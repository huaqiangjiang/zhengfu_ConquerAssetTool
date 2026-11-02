param([Parameter(Mandatory=$true)][string]$PythonExe)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
New-Item -ItemType Directory -Path '.build/packaging' -Force | Out-Null
& $PythonExe -m pip install --target '.build/packaging' 'pyinstaller==6.22.3'
if ($LASTEXITCODE -ne 0) { throw '打包工具安装失败' }
$previousPythonPath = $env:PYTHONPATH
try {
    $env:PYTHONPATH = Join-Path $PSScriptRoot '.build/packaging'
    & $PythonExe -m PyInstaller --noconfirm --onedir --noupx --contents-directory _runtime --name ConquerAssetTool --distpath '.build/dist' --workpath '.build/pyinstaller' --specpath '.build' --exclude-module numpy --exclude-module tkinter --exclude-module matplotlib 'ConquerMaxChecker/ConquerAssetTool.py'
    if ($LASTEXITCODE -ne 0) { throw '打包失败' }
    & '.build/dist/ConquerAssetTool/ConquerAssetTool.exe' --version
    if ($LASTEXITCODE -ne 0) { throw 'EXE 启动验证失败' }
    Copy-Item -LiteralPath '.build/dist/ConquerAssetTool/_runtime' -Destination 'ConquerMaxChecker' -Recurse -Force
    Copy-Item -LiteralPath '.build/dist/ConquerAssetTool/ConquerAssetTool.exe' -Destination 'ConquerMaxChecker/ConquerAssetTool.exe' -Force
} finally {
    $env:PYTHONPATH = $previousPythonPath
}
