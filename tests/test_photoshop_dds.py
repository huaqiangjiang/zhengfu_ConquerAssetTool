import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ConquerMaxChecker'))
import ConquerAssetTool as tool


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
        for version in ('auto', 'CS3', '2019', '2022', '2025'):
            with self.subTest(version=version):
                args = tool.build_parser().parse_args(['convert-dds', 'a.tga', '--ps-refine', '--ps-version', version])
                self.assertTrue(args.ps_refine)
                self.assertEqual(args.ps_version, version)


if __name__ == '__main__':
    unittest.main()
