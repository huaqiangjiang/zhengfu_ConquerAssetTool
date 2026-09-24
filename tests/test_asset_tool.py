import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('asset_tool', ROOT / 'ConquerMaxChecker/ConquerAssetTool.py')
tool = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = tool
spec.loader.exec_module(tool)


class AssetTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='conquer_test_')
        self.root = Path(self.tmp.name) / '中文 资源 & test'
        self.root.mkdir()
        self.local_data = Path(self.tmp.name) / 'LocalAppData'
        self.env_patch = patch.dict(os.environ, {'LOCALAPPDATA': str(self.local_data)})
        self.env_patch.start()

    def tearDown(self):
        self.env_patch.stop()
        self.tmp.cleanup()

    def test_legacy_3d_collection_preserves_variants(self):
        active = self.root / 'MAX' / 'asset.max'
        active.parent.mkdir(); active.write_bytes(b'edited')
        legacy = self.root / '3d'; legacy.mkdir()
        (legacy / 'asset.max').write_bytes(b'original')
        (legacy / 'face.tga').write_bytes(b'face')
        (legacy / 'body.tga').write_bytes(b'body')
        (active.parent / 'body.tga').write_bytes(b'body')
        (legacy / 'body.psd').write_bytes(b'psd')
        variant = self.root / '黑白贴图'; variant.mkdir()
        (variant / 'face.tga').write_bytes(b'other')
        self.assertEqual(0, tool.complete_hierarchy(self.root, self.root / 'reports', True, active))
        self.assertEqual(b'face', (active.parent / 'face.tga').read_bytes())
        self.assertEqual(b'other', (variant / 'face.tga').read_bytes())
        self.assertFalse((legacy / 'asset.max').exists())
        self.assertFalse((legacy / 'body.tga').exists())
        self.assertTrue((self.root / '设计稿' / 'body.psd').exists())
        self.assertEqual([active], list(active.parent.glob('*.max')))

    def test_conflicting_legacy_texture_is_not_overwritten(self):
        active = self.root / 'MAX' / 'asset.max'
        active.parent.mkdir(); active.write_bytes(b'edited')
        legacy = self.root / '3d'; legacy.mkdir()
        (legacy / 'face.tga').write_bytes(b'original')
        (active.parent / 'face.tga').write_bytes(b'different')
        self.assertEqual(2, tool.complete_hierarchy(self.root, self.root / 'reports', True, active))
        self.assertEqual(b'original', (legacy / 'face.tga').read_bytes())
        self.assertEqual(b'different', (active.parent / 'face.tga').read_bytes())

    def tga(self, name='贴图.tga', mode='RGBA'):
        p = self.root / 'MAX' / name
        p.parent.mkdir(exist_ok=True)
        im = Image.new(mode, (8, 4))
        im.putdata([(x * 7, 30, 90, x * 8) if mode == 'RGBA' else (x * 7, 30, 90) for x in range(32)])
        im.save(p)
        return p

    def test_png_preserves_pixels_and_alpha(self):
        p = self.tga()
        original = p.read_bytes()
        result = tool.convert_source_to_png(p)
        self.assertFalse(result['errors'])
        with Image.open(p) as a, Image.open(result['converted'][0]['output']) as b:
            self.assertEqual(a.size, b.size)
            self.assertEqual(a.tobytes(), b.tobytes())
        self.assertEqual(original, p.read_bytes())

    def test_rgb_stays_rgb(self):
        result = tool.convert_source_to_png(self.tga(mode='RGB'))
        with Image.open(result['converted'][0]['output']) as im:
            self.assertEqual('RGB', im.mode)

    def test_rle_tga(self):
        p = self.tga()
        with Image.open(p) as im:
            im.load()
            im.save(p, compression='tga_rle')
        self.assertEqual(1, len(tool.convert_source_to_png(p)['converted']))

    def test_corrupt_tga_does_not_replace_existing_png(self):
        p = self.tga()
        out = self.root / 'C3'
        out.mkdir()
        old = out / (p.stem + '.png')
        old.write_bytes(b'old output')
        p.write_bytes(b'broken')
        result = tool.convert_source_to_png(p)
        self.assertEqual(1, len(result['errors']))
        self.assertEqual(b'old output', old.read_bytes())
        self.assertFalse(list(out.glob('.conquer_*')))

    def test_missing_input_is_not_silent_partial_success(self):
        p = self.tga()
        result = tool.convert_source_to_png([p, p.parent / 'missing.tga'])
        self.assertEqual(1, len(result['converted']))
        self.assertEqual(1, len(result['errors']))
        reports = self.root / 'reports'
        self.assertEqual(1, tool.run_png_conversion([p, p.parent / 'missing.tga'], report_output=reports))
        self.assertTrue((reports / 'conquer_png_convert.status').read_text(encoding='utf-8-sig').startswith('ERROR'))

    def test_same_stem_conflict_blocks_both(self):
        p = self.tga()
        other = self.root / 'other'
        other.mkdir()
        q = other / p.name
        q.write_bytes(p.read_bytes())
        out = self.root / 'C3'
        for converter in (tool.convert_source_to_png, tool.convert_source_to_dds):
            result = converter([p, q], out)
            self.assertFalse(result['converted'])
            self.assertEqual(2, len(result['errors']))

    def test_dds_alpha_selects_format(self):
        for mode, fmt in [('RGB', 'DXT1'), ('RGBA', 'DXT5')]:
            p = self.tga(mode + '.tga', mode)
            with patch.object(tool, '_find_compressonator_cli', return_value=None):
                result = tool.convert_source_to_dds(p)
            self.assertFalse(result['errors'], result)
            self.assertEqual(fmt, result['converted'][0]['fourcc'])
            self.assertEqual(2, result['converted'][0]['mipmaps'])

    def test_dds_corruption_keeps_old_output(self):
        p = self.tga()
        out = self.root / 'C3'
        out.mkdir()
        old = out / (p.stem + '.dds')
        old.write_bytes(b'old dds')
        p.write_bytes(b'corrupt')
        result = tool.convert_source_to_dds(p)
        self.assertTrue(result['errors'])
        self.assertEqual(b'old dds', old.read_bytes())

    def test_png_satisfies_delivery_pair(self):
        p = self.tga()
        tool.convert_source_to_png(p)
        report = tool.AssetReport(root=str(self.root))
        tool.check_pairs(self.root, [p.parent], report)
        self.assertTrue(report.findings)
        self.assertTrue(all(x.status == '通过' for x in report.findings))

    def test_hierarchy_preserves_designs_max_versions_and_collision(self):
        old_source = self.root / 'hero.max'
        old_source.write_bytes(b'old source')
        target = self.root / 'MAX'
        target.mkdir()
        (target / 'other.max').write_bytes(b'other max')
        active = target / 'hero.max'
        active.write_bytes(b'active max')
        design = self.root / '设计稿'
        design.mkdir()
        (design / '画稿.png').write_bytes(b'design')
        (self.root / '原画.psd').write_bytes(b'psd')
        (self.root / 'notes.txt').write_bytes(b'notes')
        (self.root / '游戏.uoc').write_bytes(b'uoc')
        self.assertEqual(0, tool.complete_hierarchy(self.root, self.root / 'reports', True, active))
        self.assertEqual(b'active max', active.read_bytes())
        self.assertEqual([active], list(target.glob('*.max')))
        self.assertFalse(old_source.exists())
        archived = list(self.local_data.rglob('*.max'))
        self.assertEqual({b'other max', b'old source'}, {p.read_bytes() for p in archived})
        self.assertEqual(0, tool.complete_hierarchy(self.root, self.root / 'reports', True, active))
        self.assertEqual(2, len(list(self.local_data.rglob('*.max'))))
        self.assertTrue((design / '画稿.png').exists())
        self.assertTrue((design / '原画.psd').exists())
        self.assertTrue((self.root / '不相关文件/notes.txt').exists())
        self.assertTrue((self.root / 'C3/游戏.uoc').exists())
        self.assertFalse((self.root.parent / '不相关文件').exists())

    def test_missing_active_max_never_archives_other_versions(self):
        folder = self.root / 'MAX'
        folder.mkdir()
        old = folder / 'old.max'
        old.write_bytes(b'old max')
        self.assertEqual(2, tool.complete_hierarchy(self.root, move_unrelated=True, active_max=folder / 'missing.max'))
        self.assertEqual(b'old max', old.read_bytes())

    def test_archive_failure_preserves_old_and_current_max(self):
        folder = self.root / 'MAX'
        folder.mkdir()
        active = folder / 'current.max'
        active.write_bytes(b'current')
        old = folder / 'old.max'
        old.write_bytes(b'old')
        with patch.object(tool.shutil, 'copy2', side_effect=OSError('backup unavailable')):
            self.assertEqual(2, tool.complete_hierarchy(self.root, move_unrelated=True, active_max=active))
        self.assertEqual(b'current', active.read_bytes())
        self.assertEqual(b'old', old.read_bytes())

    def test_active_outside_max_must_be_saved_first(self):
        active = self.root / 'current.max'
        active.write_bytes(b'current')
        self.assertEqual(2, tool.complete_hierarchy(self.root, move_unrelated=True, active_max=active))
        self.assertFalse((self.root / 'MAX').exists())

    def test_hierarchy_never_touches_sibling(self):
        p = self.tga()
        active = p.parent / 'hero.max'
        active.write_bytes(b'max')
        sibling = self.root.parent / 'sibling.txt'
        sibling.write_bytes(b'sibling')
        self.assertEqual(0, tool.complete_hierarchy(self.root, self.root / 'reports', True, active))
        self.assertEqual(b'sibling', sibling.read_bytes())

    def test_broad_root_narrows_to_active(self):
        p = self.tga()
        active = p.parent / 'hero.max'
        active.write_bytes(b'max')
        self.assertEqual(0, tool.complete_hierarchy(self.root.parent, self.root / 'reports', True, active))
        self.assertFalse((self.root.parent / 'C3').exists())

    def test_neighbor_shell_does_not_expand_normal_folder(self):
        (self.root.parent / 'C3').mkdir(exist_ok=True)
        active = self.root / 'hero.max'
        active.write_bytes(b'max')
        self.assertEqual(self.root, tool.resource_root_from_active_max(active))

    def test_desktop_and_drive_are_rejected(self):
        with patch.object(tool, 'is_desktop_folder', return_value=True):
            self.assertEqual(2, tool.complete_hierarchy(self.root))
        self.assertEqual(2, tool.complete_hierarchy(Path(self.root.anchor)))

    def test_standalone_max_does_not_expand(self):
        p = self.tga()
        (p.parent / 'test.max').write_bytes(b'max')
        self.assertEqual(2, tool.complete_hierarchy(p.parent, move_unrelated=True))
        self.assertFalse((self.root / 'C3').exists())

    def test_packaged_exe_png(self):
        p = self.tga()
        output = self.root / 'C3'
        report = self.root / 'reports'
        run = subprocess.run([str(ROOT / 'ConquerMaxChecker/ConquerAssetTool.exe'), 'convert-png', str(p),
                              '--output', str(output), '--report-output', str(report)], capture_output=True)
        self.assertEqual(0, run.returncode, run.stderr)
        payload = json.loads((report / 'conquer_png_convert.json').read_text(encoding='utf-8'))
        self.assertEqual(1, len(payload['converted']))
        with Image.open(p) as source, Image.open(output / (p.stem + '.png')) as result:
            self.assertEqual(source.tobytes(), result.tobytes())

    def test_packaged_exe_reports_failure(self):
        p = self.root / 'broken.tga'
        p.write_bytes(b'broken')
        report = self.root / 'reports'
        run = subprocess.run([str(ROOT / 'ConquerMaxChecker/ConquerAssetTool.exe'), 'convert-png', str(p),
                              '--report-output', str(report)], capture_output=True)
        self.assertEqual(1, run.returncode)
        self.assertTrue((report / 'conquer_png_convert.status').read_text(encoding='utf-8-sig').startswith('ERROR'))

    def test_detection_report_is_independent_of_conversion(self):
        payload = dict(standalone_available=False, photoshop_plugin_available=False, installer_available=False,
                       standalone_converters=[], photoshop_plugins=[], installers=[])
        paths = tool.write_dds_tool_report(payload, self.root / 'reports')
        self.assertTrue(all(p.exists() for p in paths))


if __name__ == '__main__':
    unittest.main()
