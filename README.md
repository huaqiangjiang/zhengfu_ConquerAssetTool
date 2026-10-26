# 征服 MAX 模型检查器

面向 Autodesk 3ds Max 2015 的模型检查、修复、资源整理与贴图转换工具。当前版本：**v0.2.8**。

## 在其他电脑安装或更新

1. 安装 Git，克隆本仓库：
   ```powershell
   git clone https://github.com/huaqiangjiang/zhengfu_ConquerAssetTool.git
   ```
2. 以后更新时，在仓库目录运行：
   ```powershell
   git pull
   ```
3. 每次拉取更新后，将 `ConquerMaxChecker/安装到MAX启动.ms` 再拖入 3ds Max 2015，同步文件到 MAX 用户目录；关闭旧检查器窗口并重新打开，确认标题版本。

MAX 插件入口、转换程序和 Compressonator 都放在 `ConquerMaxChecker` 目录内。PS 精修会从原始 TGA 分别制作 MIP0、MIP1，使用高反差保留 1px＋叠加 100%，再由 Photoshop 的 DDS 接口编码。默认保持 TGA 尺寸和原有 MIP 层数设置；单层 DDS 只精修 MIP0，其余情况下精修前两层。支持 NVIDIA 旧式 DDS 和 Texture Tools Exporter 保存接口，PS 自动选择最新已注册版本，也可指定年份。实际兼容与验收情况见 `ConquerMaxChecker/PS精修使用说明.txt`。

## 源码构建

Windows PowerShell 中运行：

```powershell
.\build.ps1 -PythonExe "C:\Path\To\python.exe"
```

脚本在 `.build` 下准备构建环境并生成 `ConquerAssetTool.exe`。单元测试：

```powershell
$env:PYTHONPATH = "$PWD\ConquerMaxChecker"
python -m unittest discover -s tests -v
```

## 目录

- `ConquerMaxChecker/`：MAXScript、转换工具、安装脚本及运行依赖
- `tests/`：Python 与 MAXScript 验证用例

本仓库不包含用户模型、贴图、备份、运行报告或历史外发压缩包。第三方组件许可随各自组件保留。
