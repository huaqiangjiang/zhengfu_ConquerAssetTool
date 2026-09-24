#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""征服资源外部检查与整理工具初版。

本工具只处理文件系统层面的内容：
- 文件夹层级与常见文件位置
- MAX、DDS、TGA 配对
- TGA 基本格式信息
- 重复文件、临时文件、多余文件
- PSD 尺寸角色判断（贴图或设计稿）
- 桌面散文件整理预览与可选执行

Max 内部单位、材质槽、真实材质路径和模型结构仍由 ConquerMaxChecker.ms 检查。
"""

from __future__ import annotations

import argparse
import csv
import fnmatch
import hashlib
import json
import os
import re
import shutil
import subprocess
import struct
import sys
import tempfile
import uuid
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable, Optional


TOOL_VERSION = "0.2.7"
IMAGE_EXTS = {".dds", ".tga", ".psd", ".png", ".jpg", ".jpeg", ".bmp"}
TEXTURE_EXTS = set(IMAGE_EXTS)
PRODUCTION_EXTS = {".max", ".dds", ".tga"}
PREVIEW_EXTS = {".jpg"}
INTERFACE_EXTS = {".png"}
DOCUMENT_EXTS = {".doc", ".docx", ".pdf", ".xls", ".xlsx", ".csv", ".txt"}
TEMP_NAMES = {"thumbs.db", ".ds_store"}
TEMP_SUFFIXES = (".bak", ".tmp", ".old", ".autosave")
UNRELATED_DIR_NAME = "不相关文件"
SKIP_DIR_NAMES = {".git", "__pycache__", ".idea", ".vscode", UNRELATED_DIR_NAME}
MAX_DIR_SEARCH_DEPTH = 2
EXPECTED_RESOURCE_DIRS = ("C3", "MAX", "设计稿", "渲染图")
EXPECTED_RESOURCE_SUBDIRS = {"渲染图": ("界面",)}
PSD_TEXTURE_SIZES = {64, 128, 256, 512, 1024, 2048, 4096}
GENERATED_REPORT_PREFIXES = (
    "conquer_asset_check.",
    "conquer_hierarchy_fix.",
    "conquer_dds_tool.",
)
DDS_STANDALONE_NAMES = (
    "compressonatorcli.exe",
    "nvtt_export.exe",
    "nvcompress.exe",
    "texconv.exe",
)
DDS_PHOTOSHOP_SUFFIXES = {".8bi", ".8li"}
DDS_INSTALLER_PATTERNS = (
    "photoshop_plugins*.exe",
    "*dds*plugin*.exe",
)
DDS_SOURCE_EXTS = {".tga"}
DDS_PSD_REJECTION = "PSD不能转换DDS格式，只允许TGA转换。"
DDS_DEFAULT_SIZE = 0
DDS_DEFAULT_MIP_COUNT = 2
DDS_DDSD_MIPMAPCOUNT = 0x20000
DDS_DDSCAPS_COMPLEX = 0x00000008
DDS_DDSCAPS_MIPMAP = 0x00400000
DDS_SCAN_SKIP_DIRS = {
    ".git",
    "__pycache__",
    "node_modules",
    "windowsapps",
    "packages",
    "cache",
    "caches",
    "temp",
    "tmp",
}
FOLDER_ALLOWED_EXTS: dict[str, set[str]] = {
    "C3": {".c3", ".dds", ".png", ".uoc"},
    "MAX": {".max", ".tga"},
    "渲染图": PREVIEW_EXTS,
    "渲染图/界面": INTERFACE_EXTS,
    "设计稿": {".png", ".jpg", ".psd"},
}


@dataclass
class Finding:
    status: str
    category: str
    target: str
    detail: str
    suggestion: str = ""
    severity: str = "info"


@dataclass
class AssetReport:
    root: str
    tool_version: str = TOOL_VERSION
    findings: list[Finding] = field(default_factory=list)
    files: list[dict[str, Any]] = field(default_factory=list)
    summary: dict[str, int] = field(default_factory=dict)
    requires_max_check: list[str] = field(default_factory=list)

    def add(
        self,
        status: str,
        category: str,
        target: str,
        detail: str,
        suggestion: str = "",
        severity: str = "info",
    ) -> None:
        self.findings.append(
            Finding(
                status=status,
                category=category,
                target=target,
                detail=detail,
                suggestion=suggestion,
                severity=severity,
            )
        )

    def finalize(self) -> None:
        counts: dict[str, int] = {}
        for finding in self.findings:
            counts[finding.status] = counts.get(finding.status, 0) + 1
        self.summary = counts


def norm_key(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"(_2|_sharp|_sharpen)$", "", value)
    return value


def display_path(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def file_hash(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha1()
    with path.open("rb") as stream:
        while chunk := stream.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def parse_dds(path: Path) -> dict[str, Any]:
    result: dict[str, Any] = {"format": "DDS", "valid": False}
    try:
        with path.open("rb") as stream:
            header = stream.read(128)
        if len(header) < 128 or header[:4] != b"DDS ":
            result["error"] = "缺少 DDS 文件头"
            return result

        height, width = struct.unpack_from("<II", header, 12)
        mipmaps = struct.unpack_from("<I", header, 28)[0]
        fourcc = header[84:88].decode("ascii", errors="replace").strip("\x00 ")
        rgb_bits = struct.unpack_from("<I", header, 88)[0]
        result.update(
            {
                "valid": True,
                "width": width,
                "height": height,
                "mipmaps": mipmaps,
                "fourcc": fourcc or "未压缩",
                "rgb_bits": rgb_bits,
            }
        )
    except OSError as exc:
        result["error"] = f"读取失败：{exc}"
    return result


def parse_tga(path: Path) -> dict[str, Any]:
    result: dict[str, Any] = {"format": "TGA", "valid": False}
    try:
        with path.open("rb") as stream:
            header = stream.read(18)
        if len(header) < 18:
            result["error"] = "TGA 文件头长度不足"
            return result

        image_type = header[2]
        width, height = struct.unpack_from("<HH", header, 12)
        bits = header[16]
        descriptor = header[17]
        result.update(
            {
                "valid": image_type in {2, 3, 10, 11},
                "width": width,
                "height": height,
                "bits": bits,
                "image_type": image_type,
                "descriptor": descriptor,
            }
        )
        if image_type not in {2, 3, 10, 11}:
            result["error"] = f"暂不支持的 TGA 图像类型：{image_type}"
    except OSError as exc:
        result["error"] = f"读取失败：{exc}"
    return result


def parse_psd(path: Path) -> dict[str, Any]:
    result: dict[str, Any] = {"format": "PSD", "valid": False}
    try:
        with path.open("rb") as stream:
            header = stream.read(26)
        if len(header) < 26 or header[:4] != b"8BPS":
            result["error"] = "缺少有效 PSD 文件头"
            return result

        version = struct.unpack_from(">H", header, 4)[0]
        height = struct.unpack_from(">I", header, 14)[0]
        width = struct.unpack_from(">I", header, 18)[0]
        depth = struct.unpack_from(">H", header, 22)[0]
        color_mode = struct.unpack_from(">H", header, 24)[0]
        result.update(
            {
                "valid": version in {1, 2},
                "version": version,
                "width": width,
                "height": height,
                "depth": depth,
                "color_mode": color_mode,
            }
        )
        if version not in {1, 2}:
            result["error"] = f"不支持的 PSD 版本：{version}"
        else:
            # PSD 文件头不包含最终透明度结果，需读取图像通道判断 Alpha。
            # Pillow 不可用时保留基础 PSD 识别结果，不影响文件夹整理。
            try:
                from PIL import Image

                with Image.open(path) as image:
                    source_has_alpha = (
                        "A" in image.getbands()
                        or "transparency" in image.info
                    )
                    rgba = image.convert("RGBA")
                    alpha_min, alpha_max = rgba.getchannel("A").getextrema()
                    result.update(
                        {
                            "has_alpha": bool(
                                source_has_alpha or alpha_min < 255
                            ),
                            "alpha_min": alpha_min,
                            "alpha_max": alpha_max,
                        }
                    )
            except Exception:
                result["alpha_detection"] = "unavailable"
    except OSError as exc:
        result["error"] = f"读取失败：{exc}"
    return result


def parse_image(path: Path) -> dict[str, Any]:
    if path.suffix.lower() == ".dds":
        return parse_dds(path)
    if path.suffix.lower() == ".tga":
        return parse_tga(path)
    if path.suffix.lower() == ".psd":
        return parse_psd(path)
    return {"format": path.suffix.lower().lstrip("."), "valid": True}


def _existing_dirs(values: Iterable[Optional[str | Path]]) -> list[Path]:
    result: list[Path] = []
    seen: set[str] = set()
    for value in values:
        if not value:
            continue
        path = Path(value).expanduser()
        if not path.is_dir():
            continue
        key = os.path.normcase(str(path.resolve()))
        if key not in seen:
            seen.add(key)
            result.append(path)
    return result


def _bounded_find_files(
    roots: Iterable[Path],
    names: Optional[set[str]] = None,
    suffixes: Optional[set[str]] = None,
    name_predicate: Optional[Callable[[str], bool]] = None,
    max_depth: int = 5,
) -> list[Path]:
    found: list[Path] = []
    seen: set[str] = set()
    for root in roots:
        try:
            root_depth = len(root.parts)
            for current, dirs, files in os.walk(root):
                current_path = Path(current)
                dirs[:] = [
                    directory
                    for directory in dirs
                    if directory.casefold() not in DDS_SCAN_SKIP_DIRS
                ]
                if len(current_path.parts) - root_depth >= max_depth:
                    dirs[:] = []
                for filename in files:
                    path = current_path / filename
                    lower_name = filename.casefold()
                    if names and lower_name not in names:
                        continue
                    if suffixes and path.suffix.casefold() not in suffixes:
                        continue
                    if name_predicate and not name_predicate(lower_name):
                        continue
                    key = os.path.normcase(str(path.resolve()))
                    if key not in seen:
                        seen.add(key)
                        found.append(path)
        except OSError:
            continue
    return found


def detect_dds_tools(
    search_root: Optional[Path] = None,
    installer: Optional[Path] = None,
) -> dict[str, Any]:
    """Detect standalone DDS converters and Photoshop DDS plugins.

    Detection is intentionally read-only. An installer is reported as an
    installer only; it is never executed or treated as a converter.
    """
    path_candidates: list[Path] = []
    for name in DDS_STANDALONE_NAMES:
        located = shutil.which(name)
        if located:
            path_candidates.append(Path(located))

    script_root = Path(__file__).resolve().parent
    if getattr(sys, "frozen", False):
        try:
            script_root = Path(sys.executable).resolve().parent
        except OSError:
            pass
    program_roots: list[Path] = []
    for env_name in ("ProgramFiles", "ProgramFiles(x86)"):
        value = os.environ.get(env_name)
        if not value:
            continue
        program_root = Path(value)
        program_roots.extend(
            [
                program_root / "Adobe",
                program_root / "Common Files" / "Adobe",
                program_root / "NVIDIA Corporation",
                program_root / "Intel",
                program_root / "AMD",
            ]
        )
    roots = _existing_dirs([search_root, script_root, *program_roots])
    standalone_files = _bounded_find_files(
        roots,
        names={name.casefold() for name in DDS_STANDALONE_NAMES},
        max_depth=5,
    )
    plugin_files = _bounded_find_files(
        roots,
        suffixes=DDS_PHOTOSHOP_SUFFIXES,
        name_predicate=lambda name: "dds" in name,
        max_depth=8,
    )
    installer_files = _bounded_find_files(
        [search_root, script_root] if search_root else [script_root],
        max_depth=4,
    )
    installer_files = [
        path
        for path in installer_files
        if any(
            fnmatch.fnmatchcase(path.name.casefold(), pattern.casefold())
            for pattern in DDS_INSTALLER_PATTERNS
        )
    ]

    if installer and installer.is_file():
        installer_files.insert(0, installer)

    def unique_paths(paths: Iterable[Path]) -> list[str]:
        result: list[str] = []
        seen: set[str] = set()
        for path in paths:
            key = os.path.normcase(str(path.resolve()))
            if key not in seen:
                seen.add(key)
                result.append(str(path.resolve()))
        return result

    standalone = unique_paths(path_candidates + standalone_files)
    plugins = unique_paths(plugin_files)
    installers = unique_paths(installer_files)
    return {
        "standalone_converters": standalone,
        "photoshop_plugins": plugins,
        "installers": installers,
        "standalone_available": bool(standalone),
        "photoshop_plugin_available": bool(plugins),
        "installer_available": bool(installers),
        "recommended_mode": (
            "standalone"
            if standalone
            else "photoshop"
            if plugins
            else "install_required"
        ),
    }


def write_dds_tool_report(
    detection: dict[str, Any],
    output_dir: Optional[Path],
) -> tuple[Path, Path]:
    output = output_dir.resolve() if output_dir else Path.cwd()
    output.mkdir(parents=True, exist_ok=True)
    json_path = output / "conquer_dds_tool.json"
    txt_path = output / "conquer_dds_tool.txt"
    json_path.write_text(
        json.dumps(detection, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    lines = [
        "征服 DDS 工具检测",
        "",
        "检测结论：",
        (
            "可使用独立转换器，不需要 Photoshop。"
            if detection["standalone_available"]
            else "未找到独立转换器。"
        ),
        (
            "检测到 Photoshop DDS 插件。"
            if detection["photoshop_plugin_available"]
            else "未检测到已安装的 Photoshop DDS 插件。"
        ),
        (
            "检测到 DDS 安装程序，但安装程序本身不能直接转换图片。"
            if detection["installer_available"]
            else "未检测到 DDS 安装程序。"
        ),
        "",
        "独立转换器：",
        *(f"- {item}" for item in detection["standalone_converters"]),
        "Photoshop 插件：",
        *(f"- {item}" for item in detection["photoshop_plugins"]),
        "安装程序：",
        *(f"- {item}" for item in detection["installers"]),
    ]
    txt_path.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")
    return json_path, txt_path


def _load_image_for_dds(path: Path, target_size: int):
    try:
        from PIL import Image, ImageFilter, ImageOps
    except ImportError as exc:
        raise RuntimeError(
            "当前 Python 环境缺少 Pillow，无法读取 PSD/TGA。请安装 Pillow 后重试。"
        ) from exc

    with Image.open(path) as source:
        source_has_alpha_channel = (
            "A" in source.getbands() or "transparency" in source.info
        )
        image = ImageOps.exif_transpose(source).convert("RGBA")
    if target_size > 0 and image.size != (target_size, target_size):
        image = _resize_rgba_channels(
            image,
            (target_size, target_size),
        )
    alpha = image.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    has_alpha = source_has_alpha_channel or alpha_min < 255
    sharpened_rgb = image.convert("RGB").filter(
        ImageFilter.UnsharpMask(radius=1.0, percent=15, threshold=0)
    )
    if has_alpha:
        sharpened_source = Image.merge(
            "RGBA",
            (*sharpened_rgb.split(), alpha),
        )
        return (
            sharpened_source,
            sharpened_source,
            has_alpha,
        )
    return sharpened_rgb, sharpened_rgb, has_alpha


def _load_source_rgba_for_dds(path: Path, target_size: int):
    """Load source pixels without changing RGB before the external encode."""
    try:
        from PIL import Image, ImageOps
    except ImportError as exc:
        raise RuntimeError(
            "Pillow is required to read TGA/PSD source images."
        ) from exc

    with Image.open(path) as source:
        source_has_alpha_channel = (
            "A" in source.getbands() or "transparency" in source.info
        )
        image = ImageOps.exif_transpose(source).convert("RGBA")
    if target_size > 0 and image.size != (target_size, target_size):
        image = _resize_rgba_channels(
            image,
            (target_size, target_size),
        )
    alpha_min, alpha_max = image.getchannel("A").getextrema()
    has_alpha = source_has_alpha_channel or alpha_min < 255
    return image, has_alpha, alpha_min, alpha_max


def _load_dds_pipeline_source(path: Path, loader: Callable[[Path], Any]) -> Any:
    """
    Keep the DDS pipeline TGA-only. PSD conversion is intentionally rejected
    instead of being flattened through an intermediate image.
    """
    if path.suffix.casefold() == ".psd":
        raise ValueError(DDS_PSD_REJECTION)
    return loader(path)


def _resize_rgba_channels(image, size: tuple[int, int]):
    """Resize RGB and Alpha independently so transparent RGB is preserved."""
    from PIL import Image

    rgba = image.convert("RGBA")
    rgb = rgba.convert("RGB").resize(size, resample=Image.Resampling.LANCZOS)
    alpha = rgba.getchannel("A").resize(
        size,
        resample=Image.Resampling.LANCZOS,
    )
    return Image.merge("RGBA", (*rgb.split(), alpha))


def _find_compressonator_cli() -> Optional[Path]:
    """Find the bundled Compressonator CLI without requiring PATH setup."""
    candidates: list[Path] = []
    for env_name in ("COMPRESSONATORCLI", "COMPRESSONATOR_CLI"):
        value = os.environ.get(env_name)
        if value:
            candidates.append(Path(value))

    located = shutil.which("compressonatorcli.exe")
    if located:
        candidates.append(Path(located))

    roots = [Path(__file__).resolve().parent, Path.cwd()]
    if getattr(sys, "frozen", False):
        try:
            roots.insert(0, Path(sys.executable).resolve().parent)
        except OSError:
            pass
    candidates.extend(
        _bounded_find_files(
            roots,
            names={"compressonatorcli.exe"},
            max_depth=8,
        )
    )
    seen: set[str] = set()
    for candidate in candidates:
        try:
            resolved = candidate.expanduser().resolve()
        except OSError:
            continue
        key = os.path.normcase(str(resolved))
        if key in seen:
            continue
        seen.add(key)
        if resolved.is_file():
            return resolved
    return None


def _run_compressonator(
    image,
    pixel_format: str,
    mipmaps: bool,
) -> bytes:
    """Encode one DDS in an ASCII temp path so Windows CLI parsing is stable."""
    cli = _find_compressonator_cli()
    if cli is None:
        raise FileNotFoundError(
            "CompressonatorCLI.exe was not found. Put it beside "
            "ConquerAssetTool.py or set COMPRESSONATORCLI."
        )

    with tempfile.TemporaryDirectory(prefix="conquer_dds_") as temp_name:
        temp = Path(temp_name)
        source_path = temp / "source.png"
        output_path = temp / "encoded.dds"
        image.save(source_path, format="PNG", optimize=False)
        command = [
            str(cli),
            "-fd",
            pixel_format,
        ]
        if mipmaps:
            command.extend(["-mipsize", "1"])
        else:
            command.append("-nomipmap")
        command.extend(["-silent", str(source_path), str(output_path)])
        completed = subprocess.run(
            command,
            cwd=str(cli.parent),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
        if completed.returncode != 0 or not output_path.is_file():
            details = "\n".join(
                part.strip()
                for part in (completed.stdout, completed.stderr)
                if part and part.strip()
            )
            raise RuntimeError(
                f"CompressonatorCLI failed with exit code "
                f"{completed.returncode}: {details or 'no output'}"
            )
        return output_path.read_bytes()


def _dds_mip_payload_ranges(data: bytes) -> list[tuple[int, int, int, int]]:
    """Return every physically present DXT MIP, even if the header count differs."""
    if len(data) < 128 or data[:4] != b"DDS ":
        raise RuntimeError("Invalid DDS header.")
    fourcc = data[84:88].decode("ascii", errors="replace").strip("\x00 ")
    if fourcc not in {"DXT1", "DXT3", "DXT5"}:
        raise RuntimeError(f"Unsupported DDS compression format: {fourcc}")
    bytes_per_block = 8 if fourcc == "DXT1" else 16
    width = struct.unpack_from("<I", data, 16)[0]
    height = struct.unpack_from("<I", data, 12)[0]
    offset = 128
    ranges: list[tuple[int, int, int, int]] = []
    while offset < len(data):
        level_width = max(1, width)
        level_height = max(1, height)
        block_width = max(1, (level_width + 3) // 4)
        block_height = max(1, (level_height + 3) // 4)
        level_size = block_width * block_height * bytes_per_block
        end = offset + level_size
        if end > len(data):
            raise RuntimeError("DDS MIP payload is incomplete.")
        ranges.append((level_width, level_height, offset, end))
        offset = end
        width = max(1, width // 2)
        height = max(1, height // 2)
    return ranges


def _build_sharpened_mip2(image):
    """Resize RGB/Alpha independently, then sharpen RGB only for MIP 2."""
    from PIL import Image, ImageFilter

    mip_size = (
        max(1, image.width // 2),
        max(1, image.height // 2),
    )
    rgb = image.convert("RGB").resize(
        mip_size,
        resample=Image.Resampling.LANCZOS,
    )
    rgb = rgb.filter(
        ImageFilter.UnsharpMask(
            radius=1.0,
            percent=15,
            threshold=0,
        )
    )
    alpha = image.getchannel("A").resize(
        mip_size,
        resample=Image.Resampling.LANCZOS,
    )
    return Image.merge("RGBA", (*rgb.split(), alpha))


def _encode_with_compressonator_profile(
    image,
    pixel_format: str,
    header_mip_count: int,
) -> tuple[bytes, dict[str, Any]]:
    """Create the tested profile: full MIPs plus a sharpened second MIP."""
    full_data = _run_compressonator(image, pixel_format, mipmaps=True)
    full_ranges = _dds_mip_payload_ranges(full_data)
    if len(full_ranges) < 2:
        raise RuntimeError("Compressonator output does not contain MIP 2.")

    mip2_image = _build_sharpened_mip2(image)
    mip2_data = _run_compressonator(
        mip2_image,
        pixel_format,
        mipmaps=False,
    )
    mip2_ranges = _dds_mip_payload_ranges(mip2_data)
    if len(mip2_ranges) != 1:
        raise RuntimeError("MIP 2 temporary DDS contains an unexpected MIP chain.")
    mip2_payload = mip2_data[
        mip2_ranges[0][2] : mip2_ranges[0][3]
    ]
    mip2_width, mip2_height, mip2_start, mip2_end = full_ranges[1]
    if (mip2_width, mip2_height) != mip2_image.size:
        raise RuntimeError("MIP 2 dimensions do not match the source image.")
    if len(mip2_payload) != mip2_end - mip2_start:
        raise RuntimeError("MIP 2 payload size does not match the target DDS.")

    output = bytearray(full_data)
    output[mip2_start:mip2_end] = mip2_payload
    count = min(max(1, header_mip_count), len(full_ranges))
    output = bytearray(output[:full_ranges[count - 1][3]])
    struct.pack_into("<I", output, 24, 0)  # Flat 2D DDS: legacy NVIDIA treats depth=1 as a volume.
    struct.pack_into("<I", output, 28, count)
    flags = struct.unpack_from("<I", output, 8)[0] & ~0x800000
    flags = (flags | 0x20000) if count > 1 else (flags & ~0x20000)
    struct.pack_into("<I", output, 8, flags)
    struct.pack_into("<I", output, 108, 0x401008 if count > 1 else 0x1000)
    struct.pack_into("<I", output, 112, 0)
    info = {
        "encoder": "CompressonatorCLI",
        "pixel_format": pixel_format,
        "physical_mipmaps": count,
        "header_mipmaps": count,
        "sharpened_mip": 2,
        "sharpen_radius": 1.0,
        "sharpen_percent": 15,
        "sharpen_threshold": 0,
        "alpha_mode": "independent resize; no sharpen or premultiply",
        "second_mip_reencoded_once": True,
        "mip2_payload_offset": mip2_start,
        "mip2_payload_bytes": len(mip2_payload),
    }
    return bytes(output), info


def _encode_pillow_dds_level(image, pixel_format: str) -> tuple[bytes, bytes]:
    from io import BytesIO

    stream = BytesIO()
    image.save(stream, format="DDS", pixel_format=pixel_format)
    encoded = stream.getvalue()
    if len(encoded) < 128 or encoded[:4] != b"DDS ":
        raise RuntimeError("Pillow 未生成有效 DDS 文件头。")
    return encoded[:128], encoded[128:]


def _encode_dxt5_level_with_separate_alpha(image) -> tuple[bytes, bytes]:
    from PIL import Image

    rgba = image.convert("RGBA")
    rgb = rgba.convert("RGB")
    zero_rgb = Image.new("L", rgba.size, 0)
    alpha_only_image = Image.merge(
        "RGBA",
        (zero_rgb, zero_rgb, zero_rgb, rgba.getchannel("A")),
    )

    # Build the RGB payload from the source color again, with an opaque
    # temporary Alpha. This mirrors the manual workflow: create the DDS
    # MIPs/Alpha first, then replace the color and save. DXT5's own color
    # blocks are retained because they use the correct BC3 color mode.
    opaque_alpha = Image.new("L", rgba.size, 255)
    opaque_rgb_image = Image.merge(
        "RGBA",
        (*rgb.split(), opaque_alpha),
    )
    _, color_dds_payload = _encode_pillow_dds_level(
        opaque_rgb_image,
        "DXT5",
    )
    alpha_header, alpha_payload = _encode_pillow_dds_level(
        alpha_only_image,
        "DXT5",
    )
    if (
        len(color_dds_payload) != len(alpha_payload)
        or len(alpha_payload) % 16
    ):
        raise RuntimeError("DXT5 的 RGB 与 Alpha 压缩块长度不一致。")

    combined = bytearray(len(alpha_payload))
    for offset in range(0, len(combined), 16):
        combined[offset : offset + 8] = alpha_payload[offset : offset + 8]
        combined[offset + 8 : offset + 16] = color_dds_payload[
            offset + 8 : offset + 16
        ]
    return alpha_header, bytes(combined)


def _encode_dds_level(image, pixel_format: str) -> tuple[bytes, bytes]:
    if pixel_format == "DXT5":
        return _encode_dxt5_level_with_separate_alpha(image)
    return _encode_pillow_dds_level(image, pixel_format)


def _force_opaque_dxt1_level(payload: bytes) -> tuple[bytes, int]:
    """Remove DXT1's implicit transparent mode from an opaque image level."""
    if len(payload) % 8:
        raise RuntimeError("DXT1 压缩数据长度不是完整的 8 字节块。")

    fixed = bytearray(payload)
    alpha_mode_blocks = 0
    for offset in range(0, len(fixed), 8):
        color0, color1 = struct.unpack_from("<HH", fixed, offset)
        if color0 > color1:
            continue

        alpha_mode_blocks += 1
        if color0 < color1:
            new_color0, new_color1 = color1, color0
        elif color0 < 0xFFFF:
            new_color0, new_color1 = color0 + 1, color1
        else:
            new_color0, new_color1 = color0, color1 - 1
        struct.pack_into("<HH", fixed, offset, new_color0, new_color1)

        indices = struct.unpack_from("<I", fixed, offset + 4)[0]
        remapped = 0
        for shift in range(0, 32, 2):
            old_index = (indices >> shift) & 0x3
            # Swap endpoint indices; the old midpoint and transparent index
            # become the two opaque interpolated colors.
            new_index = (1, 0, 2, 3)[old_index]
            remapped |= new_index << shift
        struct.pack_into("<I", fixed, offset + 4, remapped)

    return bytes(fixed), alpha_mode_blocks


def _count_dxt1_alpha_mode_blocks(data: bytes) -> int:
    """Count DXT1 blocks that actually use the transparent palette entry.

    ``color0 <= color1`` only selects DXT1's legal three-color mode. It is
    not itself evidence of transparency: the block must also reference index
    3 in one of its sixteen 2-bit pixel indices.
    """
    if len(data) < 128 or data[:4] != b"DDS ":
        raise RuntimeError("无法读取 DXT1 DDS 文件头。")
    fourcc = data[84:88].decode("ascii", errors="replace").strip("\x00 ")
    if fourcc != "DXT1":
        return 0

    height, width = struct.unpack_from("<II", data, 12)
    mipmaps = struct.unpack_from("<I", data, 28)[0] or 1
    offset = 128
    count = 0
    level_width, level_height = width, height
    for _ in range(mipmaps):
        block_width = max(1, (level_width + 3) // 4)
        block_height = max(1, (level_height + 3) // 4)
        level_size = block_width * block_height * 8
        end = offset + level_size
        if end > len(data):
            raise RuntimeError("DXT1 DDS 的 MIP 数据不完整。")
        for block_offset in range(offset, end, 8):
            color0, color1 = struct.unpack_from("<HH", data, block_offset)
            if color0 > color1:
                continue
            indices = struct.unpack_from("<I", data, block_offset + 4)[0]
            if any(((indices >> (pixel * 2)) & 0x3) == 3 for pixel in range(16)):
                count += 1
        offset = end
        level_width = max(1, level_width // 2)
        level_height = max(1, level_height // 2)
    return count


def _dxt5_alpha_ranges_by_mip(data: bytes) -> list[tuple[int, int]]:
    if len(data) < 128 or data[:4] != b"DDS ":
        raise RuntimeError("无法读取 DXT5 DDS 文件头。")
    fourcc = data[84:88].decode("ascii", errors="replace").strip("\x00 ")
    if fourcc != "DXT5":
        return []

    height, width = struct.unpack_from("<II", data, 12)
    mipmaps = struct.unpack_from("<I", data, 28)[0] or 1
    offset = 128
    ranges: list[tuple[int, int]] = []
    level_width, level_height = width, height
    for _ in range(mipmaps):
        block_width = max(1, (level_width + 3) // 4)
        block_height = max(1, (level_height + 3) // 4)
        level_size = block_width * block_height * 16
        end = offset + level_size
        if end > len(data):
            raise RuntimeError("DXT5 DDS 的 MIP 数据不完整。")

        alpha_min, alpha_max = 255, 0
        for block_offset in range(offset, end, 16):
            alpha0 = data[block_offset]
            alpha1 = data[block_offset + 1]
            if alpha0 > alpha1:
                palette = [
                    alpha0,
                    alpha1,
                    (6 * alpha0 + alpha1) // 7,
                    (5 * alpha0 + 2 * alpha1) // 7,
                    (4 * alpha0 + 3 * alpha1) // 7,
                    (3 * alpha0 + 4 * alpha1) // 7,
                    (2 * alpha0 + 5 * alpha1) // 7,
                    (alpha0 + 6 * alpha1) // 7,
                ]
            else:
                palette = [
                    alpha0,
                    alpha1,
                    (4 * alpha0 + alpha1) // 5,
                    (3 * alpha0 + 2 * alpha1) // 5,
                    (2 * alpha0 + 3 * alpha1) // 5,
                    (alpha0 + 4 * alpha1) // 5,
                    0,
                    255,
                ]
            indices = int.from_bytes(
                data[block_offset + 2 : block_offset + 8],
                "little",
            )
            for pixel_index in range(16):
                alpha = palette[(indices >> (pixel_index * 3)) & 0x7]
                alpha_min = min(alpha_min, alpha)
                alpha_max = max(alpha_max, alpha)
        ranges.append((alpha_min, alpha_max))
        offset = end
        level_width = max(1, level_width // 2)
        level_height = max(1, level_height // 2)
    return ranges


def encode_dxt_with_mipmaps(
    image,
    pixel_format: str,
    mip_count: int = DDS_DEFAULT_MIP_COUNT,
    mip_source=None,
) -> bytes:
    """Create a DXT1/DXT5 DDS with the requested number of MIP levels.

    Pillow provides the DXT block encoders but writes one level only.
    This function keeps that encoder and rebuilds the standard DDS header
    with the requested levels, matching the NVIDIA DDS plugin profile.
    """
    from PIL import Image

    if mip_count < 1:
        raise ValueError("MIP 层数必须至少为 1。")
    if pixel_format not in {"DXT1", "DXT5"}:
        raise ValueError(f"不支持的 DDS 压缩格式：{pixel_format}")
    levels: list[bytes] = []
    current = image
    # Both levels are derived from the sharpened TGA RGB. Alpha is kept as
    # its own channel, so transparent pixels cannot contaminate RGB.
    resize_source = mip_source if mip_source is not None else image
    header, payload = _encode_dds_level(current, pixel_format)
    if pixel_format == "DXT1":
        payload, _ = _force_opaque_dxt1_level(payload)
    levels.append(payload)
    while len(levels) < mip_count:
        next_size = (
            max(1, resize_source.width // 2),
            max(1, resize_source.height // 2),
        )
        resize_source = _resize_rgba_channels(resize_source, next_size)
        current = resize_source
        _, payload = _encode_dds_level(current, pixel_format)
        if pixel_format == "DXT1":
            payload, _ = _force_opaque_dxt1_level(payload)
        levels.append(payload)

    dds_header = bytearray(header)
    struct.pack_into("<I", dds_header, 24, 0)
    flags = struct.unpack_from("<I", dds_header, 8)[0]
    flags |= DDS_DDSD_MIPMAPCOUNT
    struct.pack_into("<I", dds_header, 8, flags)
    struct.pack_into("<I", dds_header, 20, len(levels[0]))
    struct.pack_into("<I", dds_header, 28, len(levels))
    caps = struct.unpack_from("<I", dds_header, 108)[0]
    caps |= DDS_DDSCAPS_COMPLEX | DDS_DDSCAPS_MIPMAP
    struct.pack_into("<I", dds_header, 108, caps)
    return bytes(dds_header) + b"".join(levels)


def _dds_output_dir(source: Path, output_dir: Optional[Path]) -> Path:
    if output_dir:
        return output_dir.resolve()
    current = source if source.is_dir() else source.parent
    if current.name.casefold() == "tga" and current.parent.name.casefold() == "max":
        return current.parent.parent / "C3"
    if current.name.casefold() == "max":
        return current.parent / "C3"
    max_dir = find_child_dir(current, "MAX")
    if max_dir is not None:
        return max_dir.parent / "C3"
    return current / "C3"


def _dds_sources(source: Path) -> list[Path]:
    if source.is_file():
        return [source] if source.suffix.casefold() in DDS_SOURCE_EXTS else []
    if not source.is_dir():
        return []
    found: list[Path] = []
    for path in source.rglob("*"):
        try:
            relative_parts = path.relative_to(source).parts
        except ValueError:
            relative_parts = path.parts
        if (
            path.is_file()
            and path.suffix.casefold() in DDS_SOURCE_EXTS
            and not any(
                part.casefold() in DDS_SCAN_SKIP_DIRS for part in relative_parts[:-1]
            )
        ):
            found.append(path)
    return sorted(found, key=lambda item: str(item).casefold())


def _dds_rejected_psd_sources(source: Path) -> list[Path]:
    if source.suffix.casefold() == ".psd" and not source.is_dir():
        return [source]
    if not source.is_dir():
        return []
    found: list[Path] = []
    for path in source.rglob("*"):
        try:
            relative_parts = path.relative_to(source).parts
        except ValueError:
            relative_parts = path.parts
        if (
            path.is_file()
            and path.suffix.casefold() == ".psd"
            and not any(
                part.casefold() in DDS_SCAN_SKIP_DIRS for part in relative_parts[:-1]
            )
        ):
            found.append(path)
    return sorted(found, key=lambda item: str(item).casefold())


def _normalize_dds_source_paths(source: Path | list[Path]) -> list[Path]:
    if isinstance(source, Path):
        values = [source]
    else:
        values = source
    return [Path(value).resolve() for value in values]


def validate_conversion_sources(source_paths: list[Path], output_dir: Optional[Path], extension: str):
    sources: list[Path] = []
    errors: list[dict[str, str]] = []
    seen: set[str] = set()
    targets: dict[str, list[Path]] = {}
    for path in source_paths:
        if not path.exists():
            errors.append({"source": str(path), "status": "error", "error": "源文件不存在。"})
            continue
        if path.is_file() and path.suffix.casefold() != ".tga":
            errors.append({"source": str(path), "status": "error", "error": "只允许实际 TGA 文件。"})
            continue
        candidates = _dds_sources(path)
        if not candidates:
            errors.append({"source": str(path), "status": "error", "error": "未找到 TGA 文件。"})
        for candidate in candidates:
            key = str(candidate.resolve()).casefold()
            if key in seen:
                continue
            seen.add(key)
            sources.append(candidate)
            target = _dds_output_dir(candidate, output_dir) / (candidate.stem + extension)
            targets.setdefault(str(target.resolve()).casefold(), []).append(candidate)
    collisions = {str(p.resolve()).casefold() for group in targets.values() if len(group) > 1 for p in group}
    for source in sources:
        if str(source.resolve()).casefold() in collisions:
            errors.append({"source": str(source), "status": "error", "error": "同批次存在同名输出，未覆盖；请先区分源贴图名称。"})
    return [p for p in sources if str(p.resolve()).casefold() not in collisions], errors


def write_conversion_status(result: dict[str, Any], output: Path, stem: str) -> None:
    ok = bool(result["converted"]) and not result["errors"]
    lines = ["OK" if ok else "ERROR", f"成功 {len(result['converted'])}；失败 {len(result['errors'])}",
             "输出目录：" + str(result["output_dir"])]
    lines.extend(f"{i['source']}：{i.get('error', '未知错误')}" for i in result["errors"])
    (output / (stem + ".status")).write_text("\n".join(lines), encoding="utf-8-sig")


def convert_source_to_dds(
    source: Path | list[Path],
    output_dir: Optional[Path] = None,
    target_size: int = DDS_DEFAULT_SIZE,
    mip_count: int = DDS_DEFAULT_MIP_COUNT,
    ps_refine: bool = False,
    ps_version: str = "auto",
) -> dict[str, Any]:
    source_paths = _normalize_dds_source_paths(source)
    first_source = source_paths[0] if source_paths else Path.cwd()
    destination_dir = _dds_output_dir(first_source, output_dir)
    destination_dir.mkdir(parents=True, exist_ok=True)
    sources, input_errors = validate_conversion_sources(source_paths, output_dir, ".dds")
    results: list[dict[str, Any]] = list(input_errors)
    rejected_psds: list[Path] = []
    source_label = "; ".join(str(path) for path in source_paths)
    if not sources and not results:
        results.append({"source": source_label, "status": "error", "error": "未找到 TGA 文件。"})

    ps_failure = None
    for input_path in sources:
        item_destination_dir = (
            destination_dir
            if output_dir is not None
            else _dds_output_dir(input_path, None)
        )
        item_destination_dir.mkdir(parents=True, exist_ok=True)
        output_path = item_destination_dir / f"{input_path.stem}.dds"
        item: dict[str, Any] = {
            "source": str(input_path),
            "output": str(output_path),
            "status": "error",
        }
        staged_path = None
        try:
            if ps_failure:
                raise RuntimeError("本批次已因PS失败停止精修；请处理后重试：" + ps_failure)
            original_output = output_path.read_bytes() if ps_refine and output_path.exists() else None
            fd, tmp_name = tempfile.mkstemp(prefix=".conquer_", suffix=".dds", dir=item_destination_dir)
            os.close(fd)
            staged_path = Path(tmp_name)
            rgba_image, has_alpha, alpha_min, alpha_max = _load_dds_pipeline_source(
                input_path,
                lambda prepared: _load_source_rgba_for_dds(
                    prepared,
                    target_size,
                ),
            )
            pixel_format = "DXT5" if has_alpha else "DXT1"
            if _find_compressonator_cli() is not None:
                encoded_data, encode_info = _encode_with_compressonator_profile(
                    rgba_image,
                    pixel_format,
                    max(1, mip_count),
                )
                staged_path.write_bytes(encoded_data)
            else:
                image, mip_source, _ = _load_dds_pipeline_source(
                    input_path,
                    lambda prepared: _load_image_for_dds(
                        prepared,
                        target_size,
                    ),
                )
                encode_info = {
                    "encoder": "Pillow",
                    "physical_mipmaps": max(1, mip_count),
                    "header_mipmaps": max(1, mip_count),
                    "sharpened_mip": 1,
                    "second_mip_reencoded_once": False,
                    "source_pipeline": "TGA -> DDS",
                }
                staged_path.write_bytes(
                    encode_dxt_with_mipmaps(
                        image,
                        pixel_format,
                        mip_count,
                        mip_source=mip_source,
                    )
                )
            if ps_refine:
                from photoshop_dds import refine
                try:
                    encode_info['photoshop_mip1'] = refine(staged_path, input_path, ps_version)
                    encode_info['photoshop_mip1']['file'] = str(output_path)
                except Exception as exc:
                    ps_failure = str(exc)
                    raise
            parsed = parse_dds(staged_path)
            if not parsed.get("valid") or parsed.get("fourcc") != pixel_format:
                raise RuntimeError(
                    f"输出文件未通过 DDS/{pixel_format} 文件头检查。"
                )
            encoded_data = staged_path.read_bytes()
            dxt1_alpha_mode_blocks = (
                _count_dxt1_alpha_mode_blocks(encoded_data)
                if pixel_format == "DXT1"
                else 0
            )
            dxt5_alpha_mip_ranges = (
                _dxt5_alpha_ranges_by_mip(encoded_data)
                if pixel_format == "DXT5"
                else []
            )
            if dxt1_alpha_mode_blocks:
                raise RuntimeError(
                    f"DXT1 仍包含 {dxt1_alpha_mode_blocks} 个隐式透明块。"
                )
            if ps_refine and (output_path.read_bytes() if output_path.exists() else None) != original_output:
                raise RuntimeError("输出DDS在处理中被其他操作修改，未覆盖。")
            if ps_refine and output_path.exists():
                shutil.copy2(output_path, Path(encode_info['photoshop_mip1']['backup']) / 'previous-output.dds')
            os.replace(staged_path, output_path)
            item.update(
                {
                    "status": "converted",
                    "has_alpha": has_alpha,
                    "alpha_min": alpha_min,
                    "alpha_max": alpha_max,
                    "pixel_format": pixel_format,
                    "width": parsed.get("width"),
                    "height": parsed.get("height"),
                    "mipmaps": parsed.get("mipmaps"),
                    "fourcc": parsed.get("fourcc"),
                    "dxt1_alpha_mode_blocks": dxt1_alpha_mode_blocks,
                    "dxt5_alpha_mip_ranges": dxt5_alpha_mip_ranges,
                    "encode_info": encode_info,
                    "source_pipeline": "TGA -> DDS",
                }
            )
        except Exception as exc:
            item["error"] = str(exc)
        finally:
            if staged_path is not None:
                staged_path.unlink(missing_ok=True)
        results.append(item)

    for rejected in rejected_psds:
        results.append(
            {
                "source": str(rejected),
                "status": "error",
                "error": DDS_PSD_REJECTION,
            }
        )

    return {
        "source": source_label,
        "output_dir": str(destination_dir),
        "target_size": target_size,
        "mip_count": mip_count,
        "format": "Alpha 自动检测：无 Alpha=DXT1，有 Alpha=DXT5；MIP=2",
        "converted": [item for item in results if item["status"] == "converted"],
        "errors": [item for item in results if item["status"] == "error"],
    }


def write_dds_conversion_report(
    result: dict[str, Any],
    output_dir: Optional[Path],
) -> tuple[Path, Path]:
    output = output_dir.resolve() if output_dir else Path.cwd()
    output.mkdir(parents=True, exist_ok=True)
    json_path = output / "conquer_dds_convert.json"
    txt_path = output / "conquer_dds_convert.txt"
    json_path.write_text(
        json.dumps(result, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    lines = [
        "征服 TGA 转 DDS",
        "",
        f"输入：{result['source']}",
        f"输出目录：{result['output_dir']}",
        f"输出规格：{result['format']}",
        (
            "尺寸：保持源图像素尺寸"
            if result["target_size"] == 0
            else f"目标尺寸：{result['target_size']} x {result['target_size']}"
        ),
        f"MIP 层数：{result['mip_count']}",
        "",
        "转换成功：",
        *(
            f"- {item['source']} -> {item['output']} "
            f"({item.get('width')}x{item.get('height')}, "
            f"{item.get('pixel_format')}, "
            f"Alpha={'有' if item.get('has_alpha') else '无'}, "
            f"Alpha范围={item.get('alpha_min')}~{item.get('alpha_max')}, "
            f"MIP Alpha={item.get('dxt5_alpha_mip_ranges')}, "
            f"Header MIP={item.get('mipmaps')}, "
            f"Encoder={item.get('encode_info', {}).get('encoder')}, "
            f"Physical MIP={item.get('encode_info', {}).get('physical_mipmaps')}, "
            f"Sharpened MIP={item.get('encode_info', {}).get('sharpened_mip')}) "
            f"PS精修={item.get('encode_info', {}).get('photoshop_mip1', {}).get('photoshop', '未启用')} "
            f"PS精修备份={item.get('encode_info', {}).get('photoshop_mip1', {}).get('backup', '-')}"
            for item in result["converted"]
        ),
        "转换失败：",
        *(
            f"- {item['source']}：{item.get('error', '未知错误')}"
            for item in result["errors"]
        ),
    ]
    txt_path.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")
    write_conversion_status(result, output, json_path.stem)
    return json_path, txt_path


def run_dds_conversion(
    source: Path | list[Path],
    output_dir: Optional[Path] = None,
    report_output: Optional[Path] = None,
    target_size: int = DDS_DEFAULT_SIZE,
    mip_count: int = DDS_DEFAULT_MIP_COUNT,
    ps_refine: bool = False,
    ps_version: str = "auto",
) -> int:
    result = convert_source_to_dds(source, output_dir, target_size, mip_count, ps_refine, ps_version)
    json_path, txt_path = write_dds_conversion_report(result, report_output)
    print("征服 TGA 转 DDS")
    print(f"成功转换：{len(result['converted'])}")
    print(f"转换失败：{len(result['errors'])}")
    print(f"JSON 报告：{json_path}")
    print(f"TXT 报告：{txt_path}")
    return 0 if result["converted"] and not result["errors"] else 1


def convert_source_to_png(source: Path | list[Path], output_dir: Optional[Path] = None) -> dict[str, Any]:
    from PIL import Image
    source_paths = _normalize_dds_source_paths(source)
    destination_dir = _dds_output_dir(source_paths[0] if source_paths else Path.cwd(), output_dir)
    sources, results = validate_conversion_sources(source_paths, output_dir, ".png")
    for input_path in sources:
        target_dir = _dds_output_dir(input_path, output_dir)
        output_path = target_dir / (input_path.stem + ".png")
        item = {"source": str(input_path), "output": str(output_path), "status": "error"}
        staged_path = None
        try:
            image, has_alpha, lo, hi = _load_source_rgba_for_dds(input_path, 0)
            if not has_alpha:
                image = image.convert("RGB")
            target_dir.mkdir(parents=True, exist_ok=True)
            fd, tmp_name = tempfile.mkstemp(prefix=".conquer_", suffix=".png", dir=target_dir)
            os.close(fd)
            staged_path = Path(tmp_name)
            image.save(staged_path, format="PNG")
            with Image.open(staged_path) as check:
                check.load()
                if check.size != image.size or check.mode != image.mode or check.tobytes() != image.tobytes():
                    raise RuntimeError("PNG 回读校验失败：尺寸、颜色或 Alpha 与源图不一致。")
            os.replace(staged_path, output_path)
            item.update(status="converted", has_alpha=has_alpha, alpha_min=lo, alpha_max=hi, width=image.width, height=image.height)
        except Exception as exc:
            item["error"] = str(exc)
        finally:
            if staged_path is not None:
                staged_path.unlink(missing_ok=True)
        results.append(item)
    if not results:
        results.append({"source": "", "status": "error", "error": "未找到 TGA 文件。"})
    return {"source": "; ".join(map(str, source_paths)), "output_dir": str(destination_dir),
            "format": "TGA -> PNG，原尺寸，逐像素与 Alpha 回读校验",
            "converted": [i for i in results if i["status"] == "converted"],
            "errors": [i for i in results if i["status"] == "error"]}


def write_png_conversion_report(
    result: dict[str, Any],
    output_dir: Optional[Path],
) -> tuple[Path, Path]:
    output = output_dir.resolve() if output_dir else Path.cwd()
    output.mkdir(parents=True, exist_ok=True)
    json_path = output / "conquer_png_convert.json"
    txt_path = output / "conquer_png_convert.txt"
    json_path.write_text(
        json.dumps(result, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    lines = [
        "MAX 贴图 TGA 转 PNG",
        "",
        f"输入：{result['source']}",
        f"输出目录：{result['output_dir']}",
        f"格式：{result['format']}",
        "",
        "转换成功：",
        *(
            f"- {item['source']} -> {item['output']} "
            f"({item.get('width')}x{item.get('height')}, "
            f"Alpha={'有' if item.get('has_alpha') else '无'}, "
            f"Alpha范围={item.get('alpha_min')}~{item.get('alpha_max')})"
            for item in result["converted"]
        ),
        "转换失败：",
        *(
            f"- {item['source']}：{item.get('error', '未知错误')}"
            for item in result["errors"]
        ),
    ]
    txt_path.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")
    write_conversion_status(result, output, json_path.stem)
    return json_path, txt_path


def run_png_conversion(
    source: Path | list[Path],
    output_dir: Optional[Path] = None,
    report_output: Optional[Path] = None,
) -> int:
    result = convert_source_to_png(source, output_dir)
    json_path, txt_path = write_png_conversion_report(result, report_output)
    print("MAX 贴图 TGA 转 PNG")
    print(f"成功转换：{len(result['converted'])}")
    print(f"转换失败：{len(result['errors'])}")
    print(f"JSON 报告：{json_path}")
    print(f"TXT 报告：{txt_path}")
    return 0 if result["converted"] and not result["errors"] else 1


def psd_role(path: Path) -> str:
    """Classify PSD by common square texture dimensions."""
    info = parse_psd(path)
    width = info.get("width")
    height = info.get("height")
    if (
        info.get("valid")
        and width == height
        and width in PSD_TEXTURE_SIZES
    ):
        return "texture"
    if info.get("valid"):
        return "design"
    return "unknown"


def is_texture_psd(path: Path) -> bool:
    return path.suffix.lower() == ".psd" and psd_role(path) == "texture"


def is_protected_asset(path: Path) -> bool:
    """Images are reported in place and are not quarantined as unrelated files."""
    return path.suffix.lower() in TEXTURE_EXTS


def folder_allows_file(folder_name: str, path: Path) -> bool:
    ext = path.suffix.lower()
    if ext != ".psd":
        return ext in FOLDER_ALLOWED_EXTS.get(folder_name, set())

    role = psd_role(path)
    if folder_name == "MAX":
        return role == "unknown"
    if folder_name == "设计稿":
        return role in {"design", "unknown"}
    return False


def iter_files(root: Path) -> Iterable[Path]:
    for current, dirs, files in _walk_dirs(root):
        for name in files:
            path = current / name
            if path.is_file():
                yield path


def _walk_dirs(root: Path) -> Iterable[tuple[Path, list[str], list[str]]]:
    """Walk while excluding development and generated folders."""
    for current, dirs, files in os.walk(root):
        dirs[:] = [
            name
            for name in dirs
            if name.lower() not in SKIP_DIR_NAMES and not name.startswith(".")
        ]
        yield Path(current), dirs, files


def find_dirs(root: Path, name: str) -> list[Path]:
    wanted = name.lower()
    found: list[Path] = []
    for current, dirs, _files in _walk_dirs(root):
        for directory_name in dirs:
            if directory_name.lower() == wanted:
                found.append(current / directory_name)
    return found


def find_child_dir(parent: Path, wanted_name: str) -> Optional[Path]:
    wanted = wanted_name.lower()
    for path in parent.iterdir():
        if path.is_dir() and path.name.lower() == wanted:
            return path
    return None


def has_direct_max_files(path: Path) -> bool:
    try:
        return any(
            child.is_file() and child.suffix.lower() == ".max"
            for child in path.iterdir()
        )
    except OSError:
        return False


def path_key(path: Path) -> str:
    """Return a case-insensitive absolute key suitable for Windows path comparison."""
    try:
        return os.path.normcase(str(path.expanduser().resolve()))
    except OSError:
        return os.path.normcase(str(path.expanduser()))


def path_is_within(path: Path, parent: Path) -> bool:
    """Return whether path is parent itself or is below parent."""
    try:
        path_key(path)
        path.resolve().relative_to(parent.resolve())
        return True
    except (OSError, ValueError):
        return False


def is_drive_root(path: Path) -> bool:
    try:
        resolved = path.resolve()
    except OSError:
        resolved = path
    return bool(resolved.anchor) and path_key(resolved) == path_key(Path(resolved.anchor))


def is_desktop_folder(path: Path) -> bool:
    candidates: list[Path] = []
    user_profile = os.environ.get("USERPROFILE")
    if user_profile:
        candidates.append(Path(user_profile) / "Desktop")
    try:
        candidates.append(Path.home() / "Desktop")
    except RuntimeError:
        pass
    return any(path_key(path) == path_key(candidate) for candidate in candidates)


def is_unsafe_resource_parent(path: Path) -> bool:
    return is_drive_root(path) or is_desktop_folder(path)


def has_resource_shell(path: Path) -> bool:
    return any(
        find_child_dir(path, name) is not None
        for name in ("C3", "设计稿", "渲染图")
    )


def resource_root_from_active_max(active_max: Optional[Path]) -> Optional[Path]:
    """Infer the package boundary from the currently opened MAX file."""
    if active_max is None:
        return None
    try:
        active_path = active_max.expanduser().resolve()
    except OSError:
        return None
    parent = active_path.parent
    if parent.name.casefold() == "max":
        boundary = parent.parent
        if is_unsafe_resource_parent(boundary):
            return parent
        return boundary

    container = parent.parent
    if parent.name.casefold() == "3d" and container.is_dir() and has_resource_shell(container) and not is_unsafe_resource_parent(container):
        return container
    return parent


def narrow_root_to_active_package(root: Path, active_max: Optional[Path]) -> Path:
    """Keep check/fix operations inside the current MAX resource boundary."""
    boundary = resource_root_from_active_max(active_max)
    if boundary is None or not boundary.is_dir():
        return root
    try:
        root_resolved = root.resolve()
        boundary_resolved = boundary.resolve()
    except OSError:
        return root

    if path_key(root_resolved) == path_key(boundary_resolved):
        return boundary_resolved
    if path_is_within(boundary_resolved, root_resolved):
        return boundary_resolved
    if active_max is not None and path_key(root_resolved) == path_key(active_max.parent):
        return boundary_resolved
    if (
        active_max is not None
        and active_max.parent.name.casefold() == "max"
        and path_key(root_resolved) == path_key(active_max.parent)
    ):
        return boundary_resolved
    return root


def find_max_dirs(root: Path) -> list[Path]:
    """Find folders containing MAX files without walking outside the package shell."""
    root = root.resolve()
    if not root.is_dir():
        return []
    if has_direct_max_files(root):
        return [root]

    found: list[Path] = []
    seen: set[str] = set()
    pending: list[tuple[Path, int]] = [(root, 0)]
    while pending:
        current, depth = pending.pop(0)
        if depth > 0 and has_direct_max_files(current):
            key = path_key(current)
            if key not in seen:
                seen.add(key)
                found.append(current)
            continue
        if depth >= MAX_DIR_SEARCH_DEPTH:
            continue
        try:
            children = list(current.iterdir())
        except OSError:
            continue
        for child in children:
            if not child.is_dir():
                continue
            if child.name.lower() in SKIP_DIR_NAMES or child.name.startswith("."):
                continue
            pending.append((child, depth + 1))
    return found


def max_dir_for_resource_root(
    resource_root: Path, max_dirs: list[Path]
) -> Optional[Path]:
    direct_max_folder = find_child_dir(resource_root, "MAX")
    if resource_root.name.casefold() == "max" and has_direct_max_files(resource_root):
        return resource_root
    for path in max_dirs:
        if path.parent == resource_root:
            return path
    if has_direct_max_files(resource_root):
        # MAX files are flat in the package root; the MAX folder is missing.
        return direct_max_folder
    return direct_max_folder


def folder_allowed_exts(folder_name: str) -> set[str]:
    return FOLDER_ALLOWED_EXTS.get(folder_name, set())


def iter_direct_files(folder: Path) -> Iterable[Path]:
    try:
        for path in folder.iterdir():
            if path.is_file():
                yield path
    except OSError:
        return


def iter_resource_unrelated_files(
    resource_root: Path,
    excluded_paths: Optional[Iterable[Path]] = None,
) -> Iterable[tuple[Path, str, bool]]:
    """Yield files that are outside the expected package folders or have wrong formats."""
    excluded_keys = {
        path_key(path)
        for path in (excluded_paths or ())
    }
    for path in iter_direct_files(resource_root):
        if path_key(path) in excluded_keys:
            continue
        if path.name.lower().startswith(GENERATED_REPORT_PREFIXES):
            continue
        if path.suffix.lower() in TEXTURE_EXTS:
            destination = flat_file_destination(resource_root, path)
            if destination is not None:
                yield (
                    path,
                    f"文件当前直接放在资源主文件夹，应归入 {destination.parent.relative_to(resource_root)}。",
                    False,
                )
            else:
                yield path, "贴图位置需要人工确认，未自动移动。", True
        else:
            yield path, "资源主文件夹内不应直接放置文件。", False

    for folder_name in EXPECTED_RESOURCE_DIRS:
        folder = find_child_dir(resource_root, folder_name)
        if folder is None:
            continue
        for path in iter_direct_files(folder):
            if path_key(path) in excluded_keys:
                continue
            if not folder_allows_file(folder_name, path):
                is_texture = is_protected_asset(path) and not (
                    folder_name == "MAX" and is_texture_psd(path)
                )
                yield (
                    path,
                    (
                        "已识别的 PSD 贴图不属于 MAX 材质交付格式，请转换为 TGA 后放入 MAX。"
                        if folder_name == "MAX" and is_texture_psd(path)
                        else f"{folder_name} 内不允许使用 {path.suffix.lower() or '无扩展名'} 文件。"
                    ),
                    is_texture,
                )

        if folder_name == "渲染图":
            interface_dir = find_child_dir(folder, "界面")
            if interface_dir is not None:
                for path in iter_direct_files(interface_dir):
                    if path_key(path) in excluded_keys:
                        continue
                    if not folder_allows_file("渲染图/界面", path):
                        is_texture = is_protected_asset(path)
                        yield path, "渲染图/界面 内只允许放置 PNG 文件。", is_texture


def unrelated_destination(
    resource_root: Path, source: Path, unrelated_dir: Path
) -> Path:
    try:
        relative = source.relative_to(resource_root)
    except ValueError:
        relative = Path(source.name)
    return unrelated_dir / relative

def misnamed_active_max_dir(resource_root: Path, active_max: Optional[Path]) -> Optional[Path]:
    if active_max is None:
        return None
    try:
        active_path = active_max.expanduser().resolve()
        resource_root_resolved = resource_root.resolve()
    except OSError:
        return None
    source = active_path.parent
    if source.name.casefold() == "max":
        return None
    if source.parent != resource_root_resolved:
        return None
    if not has_resource_shell(resource_root_resolved):
        return None
    return source


def merge_directory_contents(
    source: Path,
    target: Path,
    actions: list[dict[str, str]],
    action_name: str,
) -> None:
    """Merge a previously generated nested folder into its package folder."""
    try:
        target.mkdir(parents=True, exist_ok=True)
        children = list(source.iterdir())
    except OSError as exc:
        actions.append(
            {
                "status": "失败",
                "action": f"{action_name}失败",
                "target": str(source),
                "detail": str(exc),
            }
        )
        return

    for child in children:
        existing_dir = find_child_dir(target, child.name) if child.is_dir() else None
        destination = existing_dir or target / child.name
        if child.is_dir() and existing_dir is not None:
            merge_directory_contents(child, existing_dir, actions, action_name)
            try:
                child.rmdir()
            except OSError:
                pass
            continue
        if child.is_file() and destination.exists():
            destination = unique_destination(destination)
        try:
            shutil.move(str(child), str(destination))
        except OSError as exc:
            actions.append(
                {
                    "status": "失败",
                    "action": f"{action_name}失败",
                    "target": str(child),
                    "detail": f"{child} -> {destination}；{exc}",
                }
            )
        else:
            actions.append(
                {
                    "status": "已移动",
                    "action": action_name,
                    "target": str(destination),
                    "detail": f"{child} -> {destination}",
                }
            )


def flatten_nested_max_package(
    resource_root: Path,
    max_dir: Path,
    actions: list[dict[str, str]],
) -> None:
    """Remove C3/MAX/design/render folders accidentally created inside MAX."""
    nested_max = find_child_dir(max_dir, "MAX")
    if nested_max is not None and nested_max != max_dir:
        merge_directory_contents(nested_max, max_dir, actions, "归并MAX内层MAX")
        try:
            nested_max.rmdir()
        except OSError:
            pass

    for folder_name in ("C3", "设计稿", "渲染图", UNRELATED_DIR_NAME):
        nested = find_child_dir(max_dir, folder_name)
        if nested is None:
            continue
        target = resource_root / folder_name
        merge_directory_contents(nested, target, actions, f"移出MAX内层{folder_name}")
        try:
            nested.rmdir()
        except OSError:
            pass


def rename_misnamed_max_dir(
    resource_root: Path,
    actions: list[dict[str, str]],
    move_unrelated: bool,
    active_max: Optional[Path] = None,
) -> Optional[Path]:
    """Rename a same-level misnamed MAX folder such as 3d to MAX."""
    source = misnamed_active_max_dir(resource_root, active_max)
    if source is None:
        return None
    target = resource_root / "MAX"
    if path_key(target) == path_key(source):
        flatten_nested_max_package(resource_root, source, actions)
        return source
    if target.exists():
        actions.append(
            {
                "status": "不通过",
                "action": "MAX重命名跳过",
                "target": str(source),
                "detail": f"目标 {target} 已存在，无法将 {source.name} 重命名为 MAX；为避免覆盖，未合并两个 MAX 文件夹。",
            }
        )
        return source
    try:
        source.rename(target)
    except OSError as exc:
        actions.append(
            {
                "status": "失败",
                "action": "重命名MAX失败",
                "target": str(source),
                "detail": f"{source} -> {target}；{exc}",
            }
        )
        return source
    actions.append(
        {
            "status": "已移动",
            "action": "重命名MAX文件夹",
            "target": str(target),
            "detail": f"{source} -> {target}",
        }
    )
    flatten_nested_max_package(resource_root, target, actions)
    return target


def flat_file_destination(root: Path, path: Path) -> Optional[Path]:
    """Return the standard folder for a file in a flat MAX-centered package."""
    ext = path.suffix.lower()
    if ext == ".max":
        return root / "MAX" / path.name
    if ext == ".dds":
        return root / "C3" / path.name
    if ext == ".psd":
        return root / "设计稿" / path.name
    if ext == ".tga":
        return root / "MAX" / path.name
    if ext == ".c3":
        return root / "C3" / path.name
    if ext == ".uoc":
        return root / "C3" / path.name
    if ext in PREVIEW_EXTS:
        return root / "渲染图" / path.name
    if ext in INTERFACE_EXTS:
        return root / "渲染图" / "界面" / path.name
    return None


def organize_flat_package(
    root: Path,
    actions: list[dict[str, str]],
    move_unrelated: bool,
    active_max: Optional[Path] = None,
) -> None:
    """Organize direct files when MAX files are currently at the package root."""
    direct_files = list(iter_direct_files(root))
    unrelated_dir = root / UNRELATED_DIR_NAME
    for source in direct_files:
        if source.name.lower().startswith(GENERATED_REPORT_PREFIXES):
            continue
        destination = flat_file_destination(root, source)
        if destination is None:
            if is_protected_asset(source):
                actions.append(
                    {
                        "status": "待处理",
                        "action": "贴图未移动",
                        "target": str(source),
                        "detail": "贴图格式或位置需要人工确认，未移动到不相关文件。",
                    }
                )
                continue
            if not move_unrelated:
                actions.append(
                    {
                        "status": "待处理",
                        "action": "未移动",
                        "target": str(source),
                        "detail": "无法按扩展名归类的文件，需人工确认。",
                    }
                )
                continue
            destination = unrelated_dir / source.name
        elif not move_unrelated:
            actions.append(
                {
                    "status": "待处理",
                    "action": "未移动",
                    "target": str(source),
                    "detail": f"建议整理到 {destination.parent.relative_to(root)}。",
                }
            )
            continue

        target = unique_destination(destination)
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(target))
        except OSError as exc:
            actions.append(
                {
                    "status": "失败",
                    "action": "移动失败",
                    "target": str(source),
                    "detail": str(exc),
                }
            )
        else:
            suffix_note = (
                "；目标重名，已自动追加后缀"
                if target.stem != source.stem
                else ""
            )
            actions.append(
                {
                    "status": "已移动",
                    "action": "按MAX中心整理",
                    "target": str(target),
                    "detail": f"{source} -> {target}{suffix_note}",
                }
            )


def resource_roots(root: Path, max_dirs: list[Path]) -> list[Path]:
    candidates: list[Path] = []
    # A folder named MAX is the production MAX subfolder; its parent is the
    # resource boundary. A non-MAX child that directly contains .max files is
    # also treated as the MAX folder when its parent already has C3/设计稿/渲染图.
    if has_direct_max_files(root):
        candidates.append(root)
    for path in max_dirs:
        if path == root:
            candidates.append(root)
        elif path.name.casefold() == "max":
            candidates.append(path.parent)
        elif path.parent == root and has_resource_shell(root):
            candidates.append(root)
        else:
            candidates.append(path)

    unique: list[Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        key = os.path.normcase(str(candidate.resolve()))
        if candidate.is_dir() and key not in seen:
            seen.add(key)
            unique.append(candidate)
    return unique


def check_resource_hierarchy(
    root: Path,
    max_dirs: list[Path],
    report: AssetReport,
    active_max: Optional[Path] = None,
) -> None:
    """Check the resource package shell without judging inner file correctness."""
    if root.name.casefold() == "max" and has_direct_max_files(root):
        max_files = [
            path
            for path in root.iterdir()
            if path.is_file() and path.suffix.lower() == ".max"
        ]
        tga_files = [
            path
            for path in root.iterdir()
            if path.is_file() and path.suffix.lower() == ".tga"
        ]
        report.add(
            "通过",
            "文件夹层级",
            display_path(root, root),
            "当前检查根目录就是 MAX 文件夹；MAX 与 TGA 为同级文件。",
            "本次整理范围不会向上处理 MAX 同级的其他文件夹。",
        )
        report.add(
            "通过" if max_files else "不通过",
            "MAX文件",
            display_path(root, root),
            f"MAX 文件 {len(max_files)} 个。",
            "至少应有一个生产 MAX 文件。",
            "error" if not max_files else "info",
        )
        report.add(
            "通过" if tga_files else "不通过",
            "TGA文件",
            display_path(root, root),
            f"TGA 文件 {len(tga_files)} 个。",
            "MAX 材质应保留并使用原始 TGA。",
        )
        return

    for resource_root in resource_roots(root, max_dirs):
        max_dir = max_dir_for_resource_root(resource_root, max_dirs)
        active_root_max = (
            active_max is not None
            and path_is_within(active_max, resource_root)
            and path_key(active_max).startswith(path_key(resource_root))
            and active_max.parent.resolve() == resource_root.resolve()
        )

        max_files = (
            [
                path
                for path in max_dir.iterdir()
                if path.is_file() and path.suffix.lower() == ".max"
            ]
            if max_dir is not None
            else []
        )
        if max_files or active_root_max:
            max_detail = (
                f"当前 MAX 文件夹名={max_dir.name if max_dir else '未建立'}；"
                f"MAX 文件数={len(max_files)}。"
            )
            if active_root_max:
                max_detail += " 当前打开 MAX 保留在资源根目录，属于允许的保护状态。"
            report.add(
                "通过"
                if max_dir is None or max_dir.name.casefold() == "max"
                else "不通过",
                "MAX文件夹命名",
                display_path(max_dir, root) if max_dir else display_path(resource_root, root),
                max_detail,
                "MAX 文件夹标准名称应为 MAX；当前名称不影响其他正确文件夹。",
                "error" if max_dir is not None and max_dir.name.casefold() != "max" else "info",
            )
        else:
            report.add(
                "不通过",
                "MAX文件夹命名",
                display_path(resource_root, root),
                "未找到包含 .max 文件的 MAX 文件夹。",
                "请确认资源主目录下存在一个直接存放 MAX 文件的文件夹。",
            )

        for folder_name in EXPECTED_RESOURCE_DIRS:
            folder = (
                max_dir
                if folder_name == "MAX" and max_dir is not None
                else find_child_dir(resource_root, folder_name)
            )
            target = f"{display_path(resource_root, root)}\\{folder_name}"
            if folder is None:
                report.add(
                    "不通过",
                    "内部文件夹",
                    target,
                    f"缺少 {folder_name} 文件夹。",
                    f"资源主文件夹内应存在 {folder_name} 文件夹。",
                    "error",
                )
                continue

            content_count = sum(1 for _ in iter_files(folder))
            if content_count == 0:
                report.add(
                    "不通过",
                    "内部文件夹内容",
                    display_path(folder, root),
                    f"{folder_name} 文件夹存在，但内部没有文件。",
                    f"请在 {folder_name} 中放入符合规则的文件。",
                    "warning",
                )
            else:
                report.add(
                    "通过",
                    "内部文件夹",
                    display_path(folder, root),
                    f"{folder_name} 文件夹存在；内部文件数={content_count}。",
                    f"已检查 {folder_name} 内文件是否有内容及扩展名是否符合规则。",
                )

            for subfolder_name in EXPECTED_RESOURCE_SUBDIRS.get(folder_name, ()):
                subfolder = find_child_dir(folder, subfolder_name)
                subtarget = f"{display_path(folder, root)}\\{subfolder_name}"
                if subfolder is None:
                    report.add(
                        "不通过",
                        "内部文件夹",
                        subtarget,
                        f"缺少 {subfolder_name} 文件夹。",
                        f"{folder_name} 内应存在 {subfolder_name} 文件夹。",
                        "error",
                    )
                else:
                    subcontent_count = sum(1 for _ in iter_files(subfolder))
                    report.add(
                        "通过" if subcontent_count > 0 else "不通过",
                        "内部文件夹内容",
                        display_path(subfolder, root),
                        f"{subfolder_name} 文件数={subcontent_count}。",
                        f"请在 {subfolder_name} 中放入 PNG 文件。",
                        "info" if subcontent_count > 0 else "warning",
                    )

        for path, reason, is_texture in iter_resource_unrelated_files(
            resource_root,
            [active_max] if active_max is not None else None,
        ):
            flat_target = (
                flat_file_destination(resource_root, path)
                if path.parent == resource_root
                else None
            )
            if is_texture:
                category = "贴图格式"
                suggestion = "贴图不自动移动，请按贴图格式和目录规则处理。"
            elif flat_target is not None:
                category = "文件夹层级"
                reason = f"文件当前直接放在资源主目录，应归入 {flat_target.parent.relative_to(resource_root)}。"
                suggestion = f"使用“整理外部层级”移动到 {flat_target.parent.relative_to(resource_root)}。"
            else:
                category = "不相关文件"
                suggestion = f"移动到 {UNRELATED_DIR_NAME} 文件夹；重名时自动追加后缀。"
            report.add(
                "不通过",
                category,
                display_path(path, root),
                reason,
                suggestion,
                "warning",
            )


def check_structure(
    root: Path,
    report: AssetReport,
    active_max: Optional[Path] = None,
) -> list[Path]:
    max_dirs = find_max_dirs(root)
    flat_max_files = (
        [
            path
            for path in root.iterdir()
            if (
                path.is_file()
                and path.suffix.lower() == ".max"
                and (
                    active_max is None
                    or path_key(path) != path_key(active_max)
                )
            )
        ]
        if root.name.lower() != "max" and max_dirs == [root]
        else []
    )
    if not max_dirs and flat_max_files:
        max_dirs = [root]
        report.add(
            "不通过",
            "文件夹层级",
            str(root),
            f"发现 {len(flat_max_files)} 个 MAX 文件直接放在当前目录，尚未按 MAX 文件夹归类。",
            "可使用“补全外部层级”，以当前目录为资源主目录自动创建并整理文件夹。",
            "warning",
        )
    if not max_dirs:
        report.add(
            "不通过",
            "文件夹层级",
            str(root),
            "未找到 MAX 文件夹。",
            "资源包中应存在 MAX 文件夹，或直接选择 MAX 文件夹作为检查根目录。",
            "error",
        )
        return []

    if not flat_max_files:
        report.add(
            "通过",
            "文件夹层级",
            str(root),
            f"找到 MAX 文件夹 {len(max_dirs)} 个。",
            "继续检查 MAX、DDS、TGA 内容。",
        )
    check_resource_hierarchy(root, max_dirs, report, active_max)

    for max_dir in max_dirs:
        relative_parts = max_dir.relative_to(root).parts
        if len(relative_parts) == 0:
            if max_dir == root and root.name.lower() != "max":
                active_root_max = (
                    active_max is not None
                    and path_is_within(active_max, root)
                    and path_key(active_max).startswith(path_key(root))
                    and active_max.parent.resolve() == root.resolve()
                    and not flat_max_files
                )
                if active_root_max:
                    hierarchy_status = "通过"
                    hierarchy_detail = "当前打开 MAX 保留在资源根目录，未向上或向 MAX 子文件夹移动。"
                else:
                    hierarchy_status = "不通过"
                    hierarchy_detail = "MAX 文件直接散放在资源主目录，尚未建立 MAX 子文件夹。"
            else:
                hierarchy_status = "通过"
                hierarchy_detail = "当前检查根目录就是 MAX 文件夹。"
        else:
            hierarchy_status = "通过" if max_dir.parent != root or len(relative_parts) == 1 else "不通过"
            hierarchy_detail = f"MAX 位于：{display_path(max_dir, root)}"
        report.add(
            hierarchy_status,
            "文件夹层级",
            display_path(max_dir, root),
            hierarchy_detail,
            "生产 MAX 和 TGA 放在 MAX；DDS 放在资源根目录的 C3。",
        )

    return max_dirs


def archive_superseded_max(source: Path, root: Path, run_id: str) -> Path:
    """Keep recoverable old scenes outside the delivery package before removing originals."""
    local_data = Path(os.environ.get("LOCALAPPDATA") or Path.home() / "AppData" / "Local")
    archive = local_data / "ConquerMaxChecker" / "backups" / "整理前旧MAX" / run_id
    target = archive / root.name / source.relative_to(root)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    if file_hash(source) != file_hash(target):
        raise OSError("旧 MAX 备份校验失败，原文件保留。")
    source.unlink()
    return target


def complete_hierarchy(root: Path, output_dir: Optional[Path] = None, move_unrelated: bool = False,
                       active_max: Optional[Path] = None) -> int:
    root = root.resolve()
    if active_max is not None:
        active_max = active_max.resolve()
        boundary = resource_root_from_active_max(active_max)
        if boundary is None or not path_is_within(active_max, root):
            print("当前 MAX 不在所选范围内，未整理。", file=sys.stderr)
            return 2
        root = boundary
        if not active_max.is_file() or active_max.suffix.lower() != ".max" or active_max.stat().st_size == 0:
            print("当前修改后的 MAX 不存在或为空，未整理。", file=sys.stderr)
            return 2
        if active_max.parent.name.casefold() != "max":
            print("请先由 MAX 将当前修改后的场景保存到 MAX 文件夹，未整理。", file=sys.stderr)
            return 2
    if not root.is_dir() or is_unsafe_resource_parent(root):
        print("资源边界无效；禁止整理桌面或磁盘根目录。", file=sys.stderr)
        return 2
    if root.name.casefold() == "max" and is_unsafe_resource_parent(root.parent):
        print("MAX 文件夹外必须再有一层资源文件夹，未向桌面或盘符扩展。", file=sys.stderr)
        return 2
    if root.name.casefold() == "max" and active_max is None:
        print("仅选中 MAX 子目录，不整理其同级目录；请选择资源主目录。", file=sys.stderr)
        return 2
    if not (has_direct_max_files(root) or find_child_dir(root, "MAX") or (active_max and path_is_within(active_max, root))):
        print("未找到本资源的 MAX，未扩大扫描范围。", file=sys.stderr)
        return 2
    actions = []
    archive_run = uuid.uuid4().hex
    folders = {}
    for name in EXPECTED_RESOURCE_DIRS:
        folder = find_child_dir(root, name) or root / name
        if not path_is_within(folder, root):
            print("标准目录链接越出资源边界，未整理。", file=sys.stderr)
            return 2
        folder.mkdir(exist_ok=True)
        folders[name] = folder
    interface = find_child_dir(folders["渲染图"], "界面") or folders["渲染图"] / "界面"
    if not path_is_within(interface, root):
        print("界面目录链接越出资源边界，未整理。", file=sys.stderr)
        return 2
    interface.mkdir(exist_ok=True)
    candidates = list(iter_direct_files(root))
    for folder in [*folders.values(), interface]:
        candidates.extend(iter_direct_files(folder))
    # Misnamed active MAX folder is handled without renaming an open scene's parent.
    if active_max and active_max.parent not in [root, *folders.values()]:
        candidates.extend(iter_direct_files(active_max.parent))
    # Only the known 3d source belonging to this scene; never scan arbitrary
    # sibling texture variants (e.g. black/white textures).
    legacy = find_child_dir(root, "3d")
    if active_max and legacy and path_is_within(legacy, root):
        legacy_scenes = list(legacy.glob("*.max"))
        if not legacy_scenes or all(p.name.casefold() == active_max.name.casefold() for p in legacy_scenes):
            candidates.extend(iter_direct_files(legacy))
    for source in dict.fromkeys(candidates):
        if source.name.lower().startswith(GENERATED_REPORT_PREFIXES):
            continue
        if active_max is not None and source.resolve() == active_max:
            continue  # Max owns saving/relocating the active scene.
        if not path_is_within(source, root):
            actions.append({"status": "失败", "target": str(source), "detail": "文件链接越出资源边界。"})
            continue
        ext = source.suffix.lower()
        if ext == ".max" and active_max is not None:
            if not move_unrelated:
                actions.append({"status": "待处理", "target": str(source), "detail": "旧 MAX 将备份到本机备份目录；MAX 仅保留当前修改后的文件。"})
                continue
            try:
                target = archive_superseded_max(source, root, archive_run)
                actions.append({"status": "已备份", "target": str(target), "detail": str(source)})
            except (OSError, ValueError) as exc:
                actions.append({"status": "失败", "target": str(source), "detail": str(exc)})
            continue
        allowed_here = any(source.parent == folder and folder_allows_file(name, source) for name, folder in folders.items())
        if allowed_here or (source.parent == interface and ext == ".png"):
            continue
        if ext in {".max", ".tga"}: target = folders["MAX"] / source.name
        elif ext in {".c3", ".dds", ".uoc"}: target = folders["C3"] / source.name
        elif ext == ".psd": target = folders["设计稿"] / source.name
        elif ext == ".jpg": target = folders["渲染图"] / source.name
        elif ext == ".png": target = interface / source.name
        else: target = root / UNRELATED_DIR_NAME / source.relative_to(root)
        if not move_unrelated:
            actions.append({"status": "待处理", "target": str(source), "detail": "建议移动到 " + str(target)})
            continue
        try:
            if ext in {".tga", ".psd"} and target.exists():
                if file_hash(source) == file_hash(target):
                    archived = archive_superseded_max(source, root, archive_run)
                    actions.append({"status": "已备份", "target": str(archived), "detail": "与目标完全相同，保留标准目录文件：" + str(source)})
                else:
                    actions.append({"status": "失败", "target": str(source), "detail": "同名文件内容不同，保留双方，未覆盖：" + str(target)})
                continue
            target = unique_destination(target)
            if not path_is_within(target, root):
                raise ValueError("目标链接越出资源边界。")
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(target))
            actions.append({"status": "已移动", "target": str(target), "detail": str(source)})
        except (OSError, ValueError) as exc:
            actions.append({"status": "失败", "target": str(source), "detail": str(exc)})
    output = output_dir.resolve() if output_dir else root
    output.mkdir(parents=True, exist_ok=True)
    (output / "conquer_hierarchy_fix.json").write_text(json.dumps({"root": str(root), "actions": actions}, ensure_ascii=False, indent=2), encoding="utf-8")
    failed = sum(i["status"] == "失败" for i in actions)
    print(f"整理完成；移动 {sum(i['status'] == '已移动' for i in actions)}；失败 {failed}。")
    return 2 if failed else 0


def check_files(root: Path, report: AssetReport) -> None:
    seen_hashes: dict[str, Path] = {}
    for path in iter_files(root):
        relative = display_path(path, root)
        info = parse_image(path)
        report.files.append(
            {
                "path": relative,
                "name": path.name,
                "extension": path.suffix.lower(),
                "size": path.stat().st_size,
                "image": info,
            }
        )

        lower_name = path.name.lower()
        if lower_name in TEMP_NAMES or path.suffix.lower() in TEMP_SUFFIXES or lower_name.startswith("~$"):
            report.add(
                "不通过",
                "临时文件",
                relative,
                "发现临时、备份或系统文件。",
                "交付前移出资源目录。",
                "error",
            )

        try:
            digest = file_hash(path)
        except OSError:
            digest = ""
        if digest:
            previous = seen_hashes.get(digest)
            if previous and previous.name != path.name:
                report.add(
                    "不通过",
                    "重复文件",
                    relative,
                    f"与 {display_path(previous, root)} 内容完全相同。",
                    "保留一份，确认是否为多余复制文件。",
                    "warning",
                )
            else:
                seen_hashes[digest] = path

        if path.suffix.lower() == ".tga":
            if not info.get("valid", False):
                report.add(
                    "不通过",
                    "贴图格式",
                    relative,
                    str(info.get("error", "图片头无效")),
                    "重新导出符合要求的 DDS/TGA。",
                    "error",
                )
            else:
                dimensions = f"{info.get('width')}x{info.get('height')}"
                report.add(
                    "通过",
                    "贴图格式",
                    relative,
                    f"TGA 有效，尺寸 {dimensions}。",
                    "继续检查 DDS 或 PNG 与 TGA 配对。",
                )


def check_pairs(root: Path, max_dirs: list[Path], report: AssetReport) -> None:
    for max_dir in max_dirs:
        package_root = max_dir.parent if max_dir.name.casefold() == "max" else max_dir
        # A standalone MAX folder check must never inspect siblings.
        if root.name.casefold() == "max" and root.resolve() == max_dir.resolve():
            continue
        c3_dir = find_child_dir(package_root, "C3")
        textures = list(c3_dir.iterdir()) if c3_dir else []
        outputs = {norm_key(p.stem) for p in textures if p.is_file() and p.suffix.lower() in {".dds", ".png"}}
        sources = {norm_key(p.stem) for p in max_dir.iterdir() if p.is_file() and p.suffix.lower() == ".tga"}
        for key in sorted(sources | outputs):
            ok = key in sources and key in outputs
            detail = "TGA 与同名 DDS 或 PNG 配套。" if ok else ("缺少源 TGA。" if key not in sources else "缺少同名 DDS 或 PNG。")
            report.add("通过" if ok else "不通过", "交付贴图配对", f"{display_path(max_dir, root)}::{key}", detail,
                       "C3 允许 DDS 或 PNG，任选一种配套即可。")


def add_max_dependency_notes(report: AssetReport) -> None:
    report.requires_max_check.extend(
        [
            "MAX 内部单位和系统单位",
            "模型是否为 Editable Poly、四边面/废点/废面",
            "材质球双面、自发光、Diffuse/Opacity 槽设置",
            "MAX 内真实贴图路径和材质引用关系",
            "Reset XForm、旋转轴、法线和场景多余对象",
        ]
    )


def write_json(report: AssetReport, output: Path) -> None:
    payload = asdict(report)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def write_csv(report: AssetReport, output: Path) -> None:
    with output.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["结果", "检查项目", "对象", "检查内容", "问题或说明", "严重性"])
        for finding in report.findings:
            writer.writerow(
                [
                    finding.status,
                    finding.category,
                    finding.target,
                    finding.detail,
                    finding.suggestion,
                    finding.severity,
                ]
            )


def write_text_report(report: AssetReport, output: Path) -> None:
    lines = [
        "征服资源外部检查报告",
        f"工具版本：{report.tool_version}",
        f"检查根目录：{report.root}",
        "",
        "结果摘要：",
        f"通过：{report.summary.get('通过', 0)}",
        f"不通过：{report.summary.get('不通过', 0)}",
        f"待确认：{report.summary.get('待确认', 0)}",
        "",
        "检查结果：",
    ]
    for finding in report.findings:
        lines.append(
            f"{finding.status} | {finding.category} | {finding.target} | "
            f"{finding.detail} | {finding.suggestion}"
        )

    if report.requires_max_check:
        lines.extend(["", "需要 Max 插件继续检查："])
        lines.extend(f"- {item}" for item in report.requires_max_check)

    output.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")


def write_max_display_report(report: AssetReport, output: Path) -> None:
    """Write a compact, MaxScript-friendly report with ASCII status tokens."""
    groups: dict[tuple[str, str], dict[str, Any]] = {}
    for finding in report.findings:
        if finding.status not in {"通过", "不通过", "待确认", "报错"}:
            continue
        key = (finding.status, finding.category)
        group = groups.setdefault(
            key,
            {
                "count": 0,
                "targets": [],
                "detail": finding.detail,
                "suggestion": finding.suggestion,
            },
        )
        group["count"] += 1
        if finding.target not in group["targets"] and len(group["targets"]) < 4:
            group["targets"].append(finding.target)
        if not group["detail"]:
            group["detail"] = finding.detail
        if not group["suggestion"]:
            group["suggestion"] = finding.suggestion

    token_by_status = {
        "通过": "PASS",
        "不通过": "FAIL",
        "待确认": "WAIT",
        "报错": "ERROR",
    }
    lines: list[str] = []
    for (status, category), group in groups.items():
        targets = "、".join(group["targets"])
        if group["count"] > 1:
            targets += f"（{group['count']}项）"
        if len(group["targets"]) >= 4:
            targets += "等"
        detail = group["suggestion"] or group["detail"] or "请根据检查项修正后重新检查。"
        if status == "报错" and group["detail"]:
            detail = f"{group['detail']}；{detail}"
        safe_fields = [
            token_by_status[status],
            category,
            targets,
            detail,
        ]
        lines.append("|".join(str(value).replace("|", "/") for value in safe_fields))

    output.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8-sig")


def run_dds_tool_detection(
    output_dir: Optional[Path] = None,
    search_root: Optional[Path] = None,
    installer: Optional[Path] = None,
) -> int:
    detection = detect_dds_tools(search_root=search_root, installer=installer)
    json_path, txt_path = write_dds_tool_report(detection, output_dir)
    print("征服 DDS 工具检测")
    print(
        "独立转换器："
        + ("已找到" if detection["standalone_available"] else "未找到")
    )
    print(
        "Photoshop DDS 插件："
        + ("已找到" if detection["photoshop_plugin_available"] else "未找到")
    )
    print(
        "DDS 安装程序："
        + ("已找到" if detection["installer_available"] else "未找到")
    )
    print(f"JSON 报告：{json_path}")
    print(f"TXT 报告：{txt_path}")
    return 0


def run_check(
    root: Path,
    output_dir: Optional[Path] = None,
    active_max: Optional[Path] = None,
) -> int:
    root = root.resolve()
    if not root.is_dir():
        print(f"路径不存在或不是文件夹：{root}", file=sys.stderr)
        return 2

    if active_max is not None:
        try:
            active_max = active_max.expanduser().resolve()
        except OSError:
            active_max = None
    root = narrow_root_to_active_package(root, active_max)

    report = AssetReport(root=str(root))
    max_dirs = check_structure(root, report, active_max)
    scan_roots = resource_roots(root, max_dirs) if max_dirs else []
    for scan_root in scan_roots:
        check_files(scan_root, report)
    check_pairs(root, max_dirs, report)
    add_max_dependency_notes(report)
    report.finalize()

    output_dir = output_dir.resolve() if output_dir else root
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "conquer_asset_check.json"
    csv_path = output_dir / "conquer_asset_check.csv"
    txt_path = output_dir / "conquer_asset_check.txt"
    max_display_path = output_dir / "conquer_asset_check_max.txt"
    write_json(report, json_path)
    write_csv(report, csv_path)
    write_text_report(report, txt_path)
    write_max_display_report(report, max_display_path)

    print_report(report)
    print(f"\nJSON 报告：{json_path}")
    print(f"CSV 报告：{csv_path}")
    print(f"TXT 报告：{txt_path}")
    print(f"Max 显示报告：{max_display_path}")
    return 0 if report.summary.get("不通过", 0) == 0 and report.summary.get("待确认", 0) == 0 else 1


def classify_for_organize(path: Path) -> tuple[str, str]:
    ext = path.suffix.lower()
    group = norm_key(path.stem) or "未命名资源"
    if ext == ".max":
        return group, "MAX"
    if ext == ".dds":
        return group, "C3"
    if ext == ".psd":
        role = psd_role(path)
        if role == "texture":
            return group, "MAX"
        if role == "unknown":
            return group, "MAX"
        return group, "设计稿"
    if ext == ".tga":
        return group, "MAX"
    if ext in PREVIEW_EXTS:
        return group, "渲染图"
    if ext in INTERFACE_EXTS:
        return group, "渲染图/界面"
    return group, "未分类"


def unique_destination(path: Path) -> Path:
    if not path.exists():
        return path
    index = 2
    while True:
        candidate = path.with_name(f"{path.stem}_{index}{path.suffix}")
        if not candidate.exists():
            return candidate
        index += 1


def move_misplaced_resource_folders(
    resource_root: Path,
    max_dir: Optional[Path],
    actions: list[dict[str, str]],
) -> None:
    """Move package folders accidentally placed inside MAX back to the root."""
    if max_dir is None or max_dir == resource_root:
        return

    for folder_name in ("C3", "设计稿", "渲染图"):
        source = find_child_dir(max_dir, folder_name)
        if source is None:
            continue

        target = resource_root / folder_name
        try:
            target.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            actions.append(
                {
                    "status": "失败",
                    "action": "创建目录失败",
                    "target": str(target),
                    "detail": str(exc),
                }
            )
            continue

        for child in list(source.iterdir()):
            destination = unique_destination(target / child.name)
            try:
                if child.is_dir() and destination.is_dir():
                    for nested in list(child.iterdir()):
                        nested_destination = unique_destination(
                            destination / nested.name
                        )
                        shutil.move(str(nested), str(nested_destination))
                    child.rmdir()
                else:
                    shutil.move(str(child), str(destination))
            except OSError as exc:
                actions.append(
                    {
                        "status": "失败",
                        "action": "移动错位文件夹内容失败",
                        "target": str(child),
                        "detail": f"{child} -> {destination}；{exc}",
                    }
                )
            else:
                actions.append(
                    {
                        "status": "已移动",
                        "action": f"归位{folder_name}",
                        "target": str(destination),
                        "detail": f"{child} -> {destination}",
                    }
                )

        try:
            source.rmdir()
        except OSError:
            pass


def move_misplaced_uoc_files(
    resource_root: Path,
    actions: list[dict[str, str]],
) -> None:
    """Move UOC files from other package folders into the root C3 folder."""
    c3_dir = find_child_dir(resource_root, "C3")
    if c3_dir is None:
        return

    source_folders: list[Path] = []
    for folder_name in ("MAX", "设计稿", "渲染图"):
        folder = find_child_dir(resource_root, folder_name)
        if folder is not None:
            source_folders.append(folder)
            if folder_name == "渲染图":
                interface_dir = find_child_dir(folder, "界面")
                if interface_dir is not None:
                    source_folders.append(interface_dir)

    for source_folder in source_folders:
        for source in iter_direct_files(source_folder):
            if source.suffix.casefold() != ".uoc":
                continue
            target = unique_destination(c3_dir / source.name)
            try:
                shutil.move(str(source), str(target))
            except OSError as exc:
                actions.append(
                    {
                        "status": "失败",
                        "action": "UOC归位失败",
                        "target": str(source),
                        "detail": f"{source} -> {target}；{exc}",
                    }
                )
            else:
                actions.append(
                    {
                        "status": "已移动",
                        "action": "UOC归位到C3",
                        "target": str(target),
                        "detail": f"{source} -> {target}",
                    }
                )


def organize(source: Path, destination: Path, apply: bool, move: bool) -> int:
    source = source.resolve()
    destination = destination.resolve()
    if not source.is_dir():
        print(f"整理源目录不存在：{source}", file=sys.stderr)
        return 2
    if destination == source or source in destination.parents:
        print("目标目录不能位于源目录内部。", file=sys.stderr)
        return 2

    plan: list[dict[str, str]] = []
    for path in iter_files(source):
        if path.name.lower() in TEMP_NAMES or path.name.startswith("~$"):
            continue
        group, category = classify_for_organize(path)
        target = destination / group / category / path.name
        plan.append(
            {
                "source": str(path),
                "target": str(target),
                "action": "移动" if move else "复制",
                "status": "待执行",
            }
        )

    plan_path = destination / "conquer_organize_plan.json"
    destination.mkdir(parents=True, exist_ok=True)
    plan_path.write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"已生成整理预览：{plan_path}")

    if not apply:
        for item in plan:
            print(f"[预览] {item['action']}：{item['source']} -> {item['target']}")
        print("当前为预览模式，没有移动或复制文件。需要执行时增加 --apply。")
        return 0

    for item in plan:
        source_path = Path(item["source"])
        target_path = unique_destination(Path(item["target"]))
        target_path.parent.mkdir(parents=True, exist_ok=True)
        if move:
            shutil.move(str(source_path), str(target_path))
        else:
            shutil.copy2(str(source_path), str(target_path))
        item["target"] = str(target_path)
        item["status"] = "已执行"
    plan_path.write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"整理完成，计划已更新：{plan_path}")
    return 0


def print_report(report: AssetReport) -> None:
    print(f"征服资源外部检查器 v{report.tool_version}")
    print(f"检查根目录：{report.root}")
    print("\n结果摘要：")
    for status in ("通过", "不通过", "待确认"):
        print(f"  {status}：{report.summary.get(status, 0)}")
    print("\n检查结果：")
    for finding in report.findings:
        print(
            f"{finding.status} | {finding.category} | {finding.target} | "
            f"{finding.detail} | {finding.suggestion}"
        )
    print("\n需要 Max 插件继续检查：")
    for item in report.requires_max_check:
        print(f"  - {item}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="征服资源外部检查与整理工具")
    parser.add_argument("--version", action="version", version=TOOL_VERSION)
    subparsers = parser.add_subparsers(dest="command", required=True)

    check_parser = subparsers.add_parser("check", help="检查资源目录")
    check_parser.add_argument("root", type=Path, help="资源包或 MAX 文件夹")
    check_parser.add_argument(
        "--output",
        type=Path,
        help="报告输出目录，默认写入检查根目录",
    )
    check_parser.add_argument(
        "--active-max",
        type=Path,
        help="当前打开的 MAX 文件；检查时将其视为允许保留在资源根目录",
    )

    dds_parser = subparsers.add_parser(
        "detect-dds",
        help="检测独立 DDS 转换器、Photoshop 插件和安装程序",
    )
    dds_parser.add_argument(
        "--output",
        type=Path,
        help="报告输出目录，默认写入当前目录",
    )
    dds_parser.add_argument(
        "--search-root",
        type=Path,
        help="额外扫描目录，例如 Photoshop 或插件安装目录",
    )
    dds_parser.add_argument(
        "--installer",
        type=Path,
        help="仅登记一个安装程序路径，不会执行安装程序",
    )

    convert_parser = subparsers.add_parser(
        "convert-dds",
        help="把 TGA 按 Alpha 自动选择 DXT1/DXT5 转换为 DDS；PSD 不允许转换",
    )
    convert_parser.add_argument(
        "source",
        type=Path,
        nargs="+",
        help="MAX 材质实际引用的 TGA 文件，或包含 TGA 的文件夹；PSD 不允许转换",
    )
    convert_parser.add_argument(
        "--output",
        type=Path,
        help="DDS 输出目录，默认自动输出到资源根的 C3 文件夹",
    )
    convert_parser.add_argument(
        "--report-output",
        type=Path,
        help="转换报告输出目录，默认写入当前目录",
    )
    convert_parser.add_argument(
        "--size",
        type=int,
        default=DDS_DEFAULT_SIZE,
        help="输出尺寸；默认 0，保持源图像素尺寸",
    )
    convert_parser.add_argument(
        "--mips",
        type=int,
        default=DDS_DEFAULT_MIP_COUNT,
        help=f"MIP 层数，默认 {DDS_DEFAULT_MIP_COUNT}",
    )

    convert_parser.add_argument("--ps-refine", action="store_true", help="由Photoshop缩小、锐化并编码mip1；失败保留原输出")
    convert_parser.add_argument("--ps-version", choices=["auto", "CS3", "2019", "2022", "2025"], default="auto")

    png_parser = subparsers.add_parser(
        "convert-png",
        help="把 TGA 无损转换为 PNG，并输出到 C3",
    )
    png_parser.add_argument(
        "source",
        type=Path,
        nargs="+",
        help="MAX 材质实际引用的 TGA 文件，或包含 TGA 的文件夹",
    )
    png_parser.add_argument(
        "--output",
        type=Path,
        help="PNG 输出目录，默认自动输出到资源根的 C3 文件夹",
    )
    png_parser.add_argument(
        "--report-output",
        type=Path,
        help="转换报告输出目录，默认写入当前目录",
    )

    fix_parser = subparsers.add_parser(
        "fix-hierarchy",
        help="创建缺失的资源层级文件夹，不移动已有文件",
    )
    fix_parser.add_argument("root", type=Path, help="资源包或 MAX 文件夹")
    fix_parser.add_argument(
        "--output",
        type=Path,
        help="补全记录输出目录，默认写入检查根目录",
    )
    fix_parser.add_argument(
        "--move-unrelated",
        action="store_true",
        help="把检测到的不相关文件移动到资源主目录下的“不相关文件”文件夹",
    )
    fix_parser.add_argument(
        "--active-max",
        type=Path,
        help="当前打开的 MAX 文件；限定资源边界，由 MAX 自己另存，其他 MAX 版本保留",
    )

    organize_parser = subparsers.add_parser("organize", help="预览或执行桌面文件整理")
    organize_parser.add_argument("source", type=Path, help="散文件目录，例如桌面")
    organize_parser.add_argument("destination", type=Path, help="整理后的目标目录")
    organize_parser.add_argument("--apply", action="store_true", help="执行整理")
    organize_parser.add_argument(
        "--move",
        action="store_true",
        help="配合 --apply 使用，移动文件；默认是复制",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except AttributeError:
            pass
    args = build_parser().parse_args(argv)
    if args.command == "check":
        return run_check(args.root, args.output, args.active_max)
    if args.command == "detect-dds":
        return run_dds_tool_detection(args.output, args.search_root, args.installer)
    if args.command == "convert-dds":
        return run_dds_conversion(
            args.source,
            args.output,
            args.report_output,
            args.size,
            args.mips,
            args.ps_refine,
            args.ps_version,
        )
    if args.command == "convert-png":
        return run_png_conversion(
            args.source,
            args.output,
            args.report_output,
        )
    if args.command == "fix-hierarchy":
        return complete_hierarchy(
            args.root,
            args.output,
            args.move_unrelated,
            args.active_max,
        )
    if args.command == "organize":
        return organize(args.source, args.destination, args.apply, args.move)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
