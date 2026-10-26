"""Photoshop high-pass refinement and DDS encoding of mip0/mip1."""
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

from dds_mip_guard import plan, commit


def resolve_photoshop(version):
    import winreg
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
                    # ProgID suffixes do not equal app.version (CC2019 uses .130).
                    # The selected executable year is checked again inside PS.
                    match = re.search(r'Photoshop\s+(?:CC\s+)?(20\d{2}|CS3)(?=[\\/\s]|$)', path, re.I)
                    label = match.group(1).upper() if match else None
                    if label and (version == 'auto' or label == version):
                        major = 10 if label == 'CS3' else int(label) - 1999
                        if major > 0:
                            found.append((label, name, major))
                except (OSError, ValueError):
                    continue
    if not found:
        raise RuntimeError('未找到已注册的 Photoshop ' + version + '。需要可用的 Photoshop 自动化注册和 DDS 保存接口。')
    found.sort(key=lambda x: (-x[2], len(x[1]), x[1]))
    return found[0]


def refine(staged, source, version='auto'):
    label, progid, major = resolve_photoshop(version)
    folder = Path(sys.executable).parent if getattr(sys, 'frozen', False) else Path(__file__).parent
    script = folder / 'PhotoshopRefine.ps1'
    if not script.is_file():
        raise RuntimeError('缺少 PhotoshopRefine.ps1，请复制完整插件目录。')
    batch = Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'ConquerMaxChecker' / 'backups' / 'PS-refine' / uuid.uuid4().hex
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
        raise RuntimeError('PS ' + label + ' 精修失败；需要可用的 NVIDIA DDS 或 Texture Tools Exporter 保存接口。\n' + detail + '\n备份：' + str(batch))
    message = result.stdout.decode('utf-8-sig', errors='replace').strip().splitlines()
    marker = next((line for line in message if line.startswith('PHOTOSHOP_REFINE_OK|')), None)
    if marker is None:
        raise RuntimeError('Photoshop 未返回精修完成标记；原输出未替换。备份：' + str(batch))
    _, interface, actual_version, resampling = marker.split('|', 3)
    verification = commit(work)
    verification.update(photoshop=label, progid=progid, backup=str(batch),
                        ddsInterface=interface, actualVersion=actual_version,
                        resampling=resampling)
    (work / 'verification.json').write_text(json.dumps(verification, ensure_ascii=False, indent=2), encoding='utf-8')
    return verification
