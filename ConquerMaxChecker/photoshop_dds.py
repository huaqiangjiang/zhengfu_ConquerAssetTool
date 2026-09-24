"""Photoshop-owned mip1 encoding; never fall back to a different DDS encoder."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

from dds_mip_guard import plan, commit, digest


def resolve_photoshop(version):
    import winreg
    majors = {'CS3': 10, '2019': 20, '2022': 23, '2025': 26}
    found = []
    for view in (winreg.KEY_WOW64_64KEY, winreg.KEY_WOW64_32KEY):
        with winreg.OpenKey(winreg.HKEY_CLASSES_ROOT, '', 0, winreg.KEY_READ | view) as root:
            for i in range(winreg.QueryInfoKey(root)[0]):
                name = winreg.EnumKey(root, i)
                if not name.startswith('Photoshop.Application.'):
                    continue
                try:
                    with winreg.OpenKey(root, name + '\\CLSID') as key:
                        clsid = winreg.QueryValue(key, None)
                    with winreg.OpenKey(root, 'CLSID\\' + clsid + '\\LocalServer32') as key:
                        command = winreg.QueryValue(key, None)
                    path = command[:command.lower().index('.exe') + 4].strip('" ')
                    if not Path(path).is_file():
                        continue
                    # Registered executable location identifies the requested year;
                    # app.version is checked again inside Photoshop before touching documents.
                    label = next((v for v in majors if any(name.lower() in path.lower() for name in ('Photoshop ' + v, 'Photoshop CC ' + v))), None)
                    if label and (version == 'auto' or label == version):
                        found.append((label, name, majors[label]))
                except (OSError, ValueError):
                    continue
    if not found:
        raise RuntimeError('未找到已注册的 Photoshop ' + version + '（支持 CS3、CC 2019、2022、2025）。请先正常安装并启动一次。')
    found.sort(key=lambda x: (-x[2], len(x[1]), x[1]))
    return found[0]


def refine(staged, source, version='auto'):
    label, progid, major = resolve_photoshop(version)
    folder = Path(sys.executable).parent if getattr(sys, 'frozen', False) else Path(__file__).parent
    script = folder / 'PhotoshopMIP1.ps1'
    if not script.is_file():
        raise RuntimeError('缺少 PhotoshopMIP1.ps1，请复制完整插件目录。')
    batch = Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'ConquerMaxChecker' / 'backups' / 'PS-mip1' / uuid.uuid4().hex
    batch.mkdir(parents=True)
    source_copy = batch / 'source.tga'
    shutil.copy2(source, source_copy)
    work = batch / 'work'
    job = plan(Path(staged), source_copy, work)
    job['expectedMajor'] = major
    (work / 'job.json').write_text(json.dumps(job, ensure_ascii=False), encoding='utf-8')
    shell = Path(os.environ.get('SystemRoot', 'C:/Windows')) / 'System32/WindowsPowerShell/v1.0/powershell.exe'
    try:
        result = subprocess.run([str(shell), '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(script), '-JobPath', str(work / 'job.json'), '-ProgId', progid], capture_output=True, timeout=180)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError('PS精修超时，请检查PS弹窗；原输出未替换。关闭未完成的PS任务后再重试。备份：' + str(batch)) from exc
    if result.returncode:
        detail = (result.stdout + result.stderr).decode('utf-8', errors='replace')
        raise RuntimeError('PS ' + label + ' 精修失败；请确认 DDS 插件能打开横向 mip 并以原 DXT 格式保存。没有采用替代编码。\n' + detail + '\n备份：' + str(batch))
    verification = commit(work)
    verification.update(photoshop=label, progid=progid, backup=str(batch))
    return verification
