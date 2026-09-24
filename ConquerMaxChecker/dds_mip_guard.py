"""Prepare Photoshop jobs and commit only a verified BC1/BC2/BC3 mip1 block."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct


def digest(data):
    return hashlib.sha256(data).hexdigest()


def parse(data):
    if len(data) < 128 or data[:4] != b'DDS ':
        raise ValueError('Not a legacy DDS')
    height, width = struct.unpack_from('<II', data, 12)
    count = max(1, struct.unpack_from('<I', data, 28)[0])
    fourcc = data[84:88]
    block = {b'DXT1': 8, b'DXT3': 16, b'DXT5': 16}.get(fourcc)
    if not block or struct.unpack_from('<I', data, 112)[0] != 0:
        raise ValueError('Only flat legacy DXT1/3/5 textures are supported')
    if not width or not height or count > 32:
        raise ValueError('Invalid dimensions/mip count')
    levels = []
    offset = 128
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
    if len(levels) < 2:
        raise ValueError('DDS needs mip1 before this operation')
    with Image.open(tga) as image:
        if image.size != levels[0][2:]:
            raise ValueError('TGA and DDS mip0 dimensions differ')
    work.mkdir(parents=True)
    shutil.copy2(dds, work / 'original.dds')
    shutil.copy2(dds, work / 'strip.dds')
    offset, size, w, h = levels[1]
    header = bytearray(data[:128])
    struct.pack_into('<II', header, 12, h, w)
    struct.pack_into('<I', header, 20, size)
    struct.pack_into('<I', header, 28, 1)
    struct.pack_into('<I', header, 8, struct.unpack_from('<I', header, 8)[0] & ~0x20000)
    struct.pack_into('<I', header, 108, 0x1000)
    (work / 'mip1.dds').write_bytes(header + data[offset:offset + size])
    job = dict(dds=str(dds), tga=str(tga), width=levels[0][2], height=levels[0][3],
               halfWidth=w, halfHeight=h, fourcc=fourcc.decode(), baselineSha256=digest(data),
               strip=str(work / 'strip.dds'), template=str(work / 'mip1.dds'),
               halfTga=str(work / 'sharpened-mip1.tga'), proof=str(work / 'photoshop-strip.png'))
    (work / 'job.json').write_text(json.dumps(job, ensure_ascii=False, indent=2), encoding='utf-8')
    return job


def commit(work):
    job = json.loads((work / 'job.json').read_text(encoding='utf-8'))
    target = Path(job['dds'])
    baseline = (work / 'original.dds').read_bytes()
    if digest(baseline) != job['baselineSha256'] or target.read_bytes() != baseline:
        raise ValueError('DDS changed since planning; do not overwrite')
    encoded = (work / 'mip1.dds').read_bytes()
    fmt, levels = parse(baseline)
    efmt, elevels = parse(encoded)
    offset, size, w, h = levels[1]
    eo, es, ew, eh = elevels[0]
    if (efmt, es, ew, eh) != (fmt, size, w, h):
        raise ValueError(f'PS导出不匹配：需要 {fmt.decode()} {w}x{h}，实际 {efmt.decode()} {ew}x{eh}；原DDS未覆盖')
    patched = baseline[:offset] + encoded[eo:eo + size] + baseline[offset + size:]
    parse(patched)
    if patched[:offset] != baseline[:offset] or patched[offset + size:] != baseline[offset + size:]:
        raise ValueError('Unexpected change outside mip1')
    temporary = target.with_name(target.name + '.mip1-tmp')
    if temporary.exists():
        raise ValueError('Stale temporary output; inspect first')
    temporary.write_bytes(patched)
    if temporary.read_bytes() != patched:
        raise OSError('Write verification failed')
    os.replace(temporary, target)
    result = dict(file=str(target), fourcc=fmt.decode(), mipCount=len(levels),
                  mip0Identical=True, unchangedOutsideMip1=True,
                  mip1Changed=baseline[offset:offset + size] != patched[offset:offset + size],
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
