import sys
import json
import struct
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ConquerMaxChecker'))
import ConquerAssetTool as tool
import dds_mip_guard as guard


class PhotoshopIntegrationTests(unittest.TestCase):
    def test_ps_failure_preserves_existing_and_stops_batch(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            a, b = root / 'a.tga', root / 'b.tga'
            for path in (a, b):
                Image.new('RGBA', (16, 16), (120, 50, 90, 180)).save(path)
            out = root / 'out'
            out.mkdir()
            old = out / 'a.dds'
            old.write_bytes(b'preserve previous file')
            with patch('photoshop_dds.refine', side_effect=RuntimeError('PS unavailable')) as refine:
                result = tool.convert_source_to_dds([a, b], out, ps_refine=True, ps_version='2025')
            self.assertEqual(old.read_bytes(), b'preserve previous file')
            self.assertFalse((out / 'b.dds').exists())
            self.assertEqual(refine.call_count, 1)
            self.assertEqual(len(result['errors']), 2)

    def test_converter_emits_exact_flat_mip_chain_before_ps(self):
        import struct
        from PIL import Image
        for mode in ('RGB', 'RGBA'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                source = root / 'source.tga'
                Image.new(mode, (16, 16), (120, 50, 90) if mode == 'RGB' else (120, 50, 90, 180)).save(source)
                def validate(staged, *args):
                    data = staged.read_bytes()
                    self.assertEqual(0, struct.unpack_from('<I', data, 24)[0])
                    self.assertEqual(2, struct.unpack_from('<I', data, 28)[0])
                    block = 8 if mode == 'RGB' else 16
                    self.assertEqual(128 + (16 + 4) * block, len(data))
                    return {'backup': str(root)}
                with patch('photoshop_dds.refine', side_effect=validate):
                    result = tool.convert_source_to_dds([source], root / 'out', ps_refine=True)
                self.assertEqual([], result['errors'])

    def test_version_cli(self):
        for version in ('auto', 'CS3', '2019', '2022', '2024', '2025', '2026'):
            with self.subTest(version=version):
                args = tool.build_parser().parse_args(['convert-dds', 'a.tga', '--ps-refine', '--ps-version', version])
                self.assertTrue(args.ps_refine)
                self.assertEqual(args.ps_version, version)


def sample_dds(width, height, count, fmt=b'DXT1', fill=20, dx10=False):
    header = bytearray(128)
    header[:4] = b'DDS '
    struct.pack_into('<7I', header, 4, 124, 0xA1007, height, width, 0, 0, count)
    struct.pack_into('<II', header, 76, 32, 4)
    header[84:88] = b'DX10' if dx10 else fmt
    struct.pack_into('<I', header, 108, 0x401008 if count > 1 else 0x1000)
    extension = struct.pack('<5I', 71 if fmt == b'DXT1' else 77, 3, 0, 1, 1) if dx10 else b''
    block = 8 if fmt == b'DXT1' else 16
    payload = b''
    for i in range(count):
        w, h = max(1, width >> i), max(1, height >> i)
        size = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * block
        payload += bytes([(fill + i) % 256]) * size
    return bytes(header) + extension + payload


class PhotoshopMipCommitTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def prepare(self, width=32, height=16, count=4, fmt=b'DXT1', source_size=None):
        from PIL import Image
        source = self.root / 'source.tga'
        Image.new('RGBA' if fmt == b'DXT5' else 'RGB', source_size or (width, height)).save(source)
        target = self.root / 'target.dds'
        before = sample_dds(width, height, count, fmt)
        target.write_bytes(before)
        work = self.root / 'work'
        job = guard.plan(target, source, work)
        for level in job['levels']:
            Path(level['encoded']).write_bytes(sample_dds(level['width'], level['height'], 1, fmt, 100 + level['index']))
        return target, before, work, job

    def test_both_mips_change_and_later_mips_and_header_are_preserved(self):
        target, before, work, job = self.prepare()
        result = guard.commit(work)
        after = target.read_bytes()
        _, levels = guard.parse(before)
        self.assertEqual([0, 1], result['refinedMips'])
        self.assertTrue(result['mip0Changed'])
        self.assertTrue(result['mip1Changed'])
        self.assertEqual(before[:128], after[:128])
        end = levels[1][0] + levels[1][1]
        self.assertEqual(before[end:], after[end:])
        self.assertEqual(len(before), len(after))
        for item in job['levels']:
            offset, size, _, _ = levels[item['index']]
            self.assertEqual(Path(item['encoded']).read_bytes()[128:], after[offset:offset + size])

    def test_single_mip_and_unchanged_pixels_are_valid(self):
        target, before, work, job = self.prepare(count=1)
        Path(job['levels'][0]['encoded']).write_bytes(before)
        result = guard.commit(work)
        self.assertEqual([0], result['refinedMips'])
        self.assertFalse(result['mip0Changed'])
        self.assertIsNone(result['mip1Changed'])

    def test_explicit_output_size_keeps_original_tga_as_ps_source(self):
        _, _, _, job = self.prepare(width=16, height=8, source_size=(64, 32))
        self.assertEqual((64, 32), (job['sourceWidth'], job['sourceHeight']))
        self.assertEqual([(16, 8), (8, 4)], [(m['width'], m['height']) for m in job['levels']])

    def test_dx10_single_mips_are_extracted_into_original_legacy_container(self):
        target, _, work, job = self.prepare(width=28, height=12, fmt=b'DXT5')
        for level in job['levels']:
            Path(level['encoded']).write_bytes(sample_dds(level['width'], level['height'], 1, b'DXT5', 120, dx10=True))
        guard.commit(work)
        self.assertEqual(b'DXT5', target.read_bytes()[84:88])
        _, levels = guard.parse(target.read_bytes())
        self.assertEqual(4, len(levels))

    def test_bad_second_mip_never_partially_commits_first_mip(self):
        target, before, work, job = self.prepare()
        Path(job['levels'][1]['encoded']).write_bytes(sample_dds(16, 8, 1, b'DXT5'))
        with self.assertRaises(ValueError):
            guard.commit(work)
        self.assertEqual(before, target.read_bytes())

    def test_extra_exported_mips_are_rejected(self):
        target, before, work, job = self.prepare()
        Path(job['levels'][0]['encoded']).write_bytes(sample_dds(32, 16, 2))
        with self.assertRaises(ValueError):
            guard.commit(work)
        self.assertEqual(before, target.read_bytes())

    def test_concurrent_target_changes_are_preserved(self):
        target, _, work, _ = self.prepare()
        target.write_bytes(b'changed elsewhere')
        with self.assertRaises(ValueError):
            guard.commit(work)
        self.assertEqual(b'changed elsewhere', target.read_bytes())

    def test_job_cannot_skip_mip0(self):
        target, before, work, job = self.prepare()
        job['levels'] = job['levels'][1:]
        (work / 'job.json').write_text(json.dumps(job), encoding='utf-8')
        with self.assertRaises(ValueError):
            guard.commit(work)
        self.assertEqual(before, target.read_bytes())

    def test_premultiplied_dx10_export_is_rejected(self):
        target, before, work, job = self.prepare()
        data = bytearray(sample_dds(32, 16, 1, dx10=True))
        struct.pack_into('<I', data, 144, 2)
        Path(job['levels'][0]['encoded']).write_bytes(data)
        with self.assertRaises(ValueError):
            guard.commit(work)
        self.assertEqual(before, target.read_bytes())


if __name__ == '__main__':
    unittest.main()
