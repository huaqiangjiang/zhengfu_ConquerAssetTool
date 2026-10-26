"""Commit independently PS-encoded mip0/mip1, preserving the remaining DDS."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct


def digest(data):
    return hashlib.sha256(data).hexdigest()


def parse(data, *, allow_dx10=False):
    if (len(data) < 128 or data[:4] != b'DDS '
            or struct.unpack_from('<I', data, 4)[0] != 124
            or struct.unpack_from('<I', data, 76)[0] != 32):
        raise ValueError('Invalid DDS header')
    height, width = struct.unpack_from('<II', data, 12)
    count = max(1, struct.unpack_from('<I', data, 28)[0])
    fourcc = data[84:88]
    offset = 128
    if fourcc == b'DX10' and allow_dx10:
        if len(data) < 148:
            raise ValueError('Truncated DX10 header')
        dxgi, dimension, misc, array_size, alpha_mode = struct.unpack_from('<5I', data, 128)
        if dimension != 3 or misc != 0 or array_size != 1 or alpha_mode not in (0, 1, 3):
            raise ValueError('Only non-premultiplied 2D DDS textures are supported')
        fourcc = {71: b'DXT1', 72: b'DXT1', 74: b'DXT3', 75: b'DXT3',
                  77: b'DXT5', 78: b'DXT5'}.get(dxgi)
        offset = 148
    block = {b'DXT1': 8, b'DXT3': 16, b'DXT5': 16}.get(fourcc)
    if (not block or struct.unpack_from('<I', data, 112)[0] != 0
            or struct.unpack_from('<I', data, 24)[0] > 1):
        raise ValueError('Only flat legacy DXT1/3/5 textures are supported')
    if not width or not height or count > 32:
        raise ValueError('Invalid dimensions/mip count')
    levels = []
    for i in range(count):
        w, h = max(1, width >> i), max(1, height >> i)
        size = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * block
        if offset + size > len(data):
            raise ValueError('Truncated mip chain')
        levels.append((offset, size, w, h))
        offset += size
    return fourcc, levels


def plan(dds, tga, work):
    from PIL import Image
    dds, tga, work = dds.resolve(), tga.resolve(), work.resolve()
    if work.exists():
        raise ValueError('Use a new work directory; never overwrite baseline')
    data = dds.read_bytes()
    fourcc, levels = parse(data)
    with Image.open(tga) as image:
        source_width, source_height = image.size
    if len(data) != levels[-1][0] + levels[-1][1]:
        raise ValueError('Baseline DDS has data outside the declared mip chain')
    work.mkdir(parents=True)
    shutil.copy2(dds, work / 'original.dds')
    outputs = [dict(index=i, width=w, height=h,
                    encoded=str(work / f'mip{i}.dds'),
                    proof=str(work / f'refined-mip{i}.tga'))
               for i, (_, _, w, h) in enumerate(levels[:2])]
    job = dict(dds=str(dds), tga=str(tga), width=levels[0][2], height=levels[0][3],
               sourceWidth=source_width, sourceHeight=source_height,
               fourcc=fourcc.decode(), baselineSha256=digest(data), levels=outputs,
               radius=1.0, opacity=100, fill=100)
    (work / 'job.json').write_text(json.dumps(job, ensure_ascii=False, indent=2), encoding='utf-8')
    return job


def commit(work):
    job = json.loads((work / 'job.json').read_text(encoding='utf-8'))
    target = Path(job['dds'])
    baseline = (work / 'original.dds').read_bytes()
    if digest(baseline) != job['baselineSha256'] or target.read_bytes() != baseline:
        raise ValueError('DDS changed since planning; do not overwrite')
    fmt, levels = parse(baseline)
    expected_indices = list(range(min(2, len(levels))))
    if [item['index'] for item in job['levels']] != expected_indices:
        raise ValueError('Photoshop job must refine mip0 and, when present, mip1')
    patched = bytearray(baseline)
    changed = {}
    for item in job['levels']:
        index = item['index']
        encoded = Path(item['encoded']).read_bytes()
        efmt, elevels = parse(encoded, allow_dx10=True)
        offset, size, w, h = levels[index]
        eo, es, ew, eh = elevels[0]
        if (len(elevels) != 1 or len(encoded) != eo + es
                or (efmt, es, ew, eh) != (fmt, size, w, h)):
            raise ValueError(f'PS MIP{index}导出不匹配：需要 {fmt.decode()} {w}x{h}；原DDS未覆盖')
        payload = encoded[eo:eo + es]
        changed[index] = baseline[offset:offset + size] != payload
        patched[offset:offset + size] = payload
    patched = bytes(patched)
    parse(patched)
    last_offset, last_size, _, _ = levels[expected_indices[-1]]
    end = last_offset + last_size
    if patched[:128] != baseline[:128] or patched[end:] != baseline[end:]:
        raise ValueError('Unexpected change outside refined mip0/mip1')
    temporary = target.with_name(target.name + '.ps-refine-tmp')
    if temporary.exists():
        raise ValueError('Stale temporary output; inspect first')
    temporary.write_bytes(patched)
    if temporary.read_bytes() != patched:
        raise OSError('Write verification failed')
    os.replace(temporary, target)
    result = dict(file=str(target), fourcc=fmt.decode(), mipCount=len(levels),
                  refinedMips=expected_indices, mip0Changed=changed[0],
                  mip1Changed=changed.get(1), unchangedOutsideRefinedMips=True,
                  method='High Pass 1px / Overlay 100%',
                  originalSha256=digest(baseline), finalSha256=digest(patched),
                  originalBackup=str(work / 'original.dds'))
    (work / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='command', required=True)
    a = sub.add_parser('plan')
    a.add_argument('dds', type=Path)
    a.add_argument('tga', type=Path)
    a.add_argument('work', type=Path)
    a = sub.add_parser('commit')
    a.add_argument('work', type=Path)
    args = p.parse_args()
    result = plan(args.dds, args.tga, args.work) if args.command == 'plan' else commit(args.work)
    print(json.dumps(result, ensure_ascii=False, indent=2))
