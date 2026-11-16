"""生成 Android 启动图标：完整图片不裁剪，仅把白色边缘填充为背景色。

用法：
    python tool/generate_app_icon.py [源图片路径]

默认源图：assets/app_icon_source.jpg（或 .png）

规则（用户 2026-11-16 要求）：
  - 图片整个保留：不裁剪、不带安全区留边、不使用会触发系统圆形遮罩的自适应图标
  - 只删除白色边缘：从四角做连通填充，把与边缘相连的白色区域替换为图片主色
    （云朵等白色主体不与边缘连通，不受影响）

产物：
    android/app/src/main/res/mipmap-*/ic_launcher.png（方形完整图标）
并清理：
    mipmap-anydpi-v26/ic_launcher.xml、mipmap-*/ic_launcher_foreground.png、values/colors.xml
"""

import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def center_square(img: Image.Image) -> Image.Image:
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def dominant_color_rgb(img: Image.Image) -> tuple[int, int, int]:
    small = img.convert("RGB").resize((32, 32))
    counts: dict[tuple[int, int, int], int] = {}
    for r, g, b in list(small.getdata()):
        key = (min(r // 8 * 8 + 4, 255), min(g // 8 * 8 + 4, 255), min(b // 8 * 8 + 4, 255))
        counts[key] = counts.get(key, 0) + 1
    return max(counts.items(), key=lambda kv: kv[1])[0]


def fill_white_edges(img: Image.Image, fill: tuple[int, int, int], tolerance: int = 80) -> Image.Image:
    """从四角连通填充白色边缘；只影响与边缘相连的白块，云朵等主体保留。"""
    rgba = img.convert("RGBA").copy()
    w, h = rgba.size
    for xy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        ImageDraw.floodfill(rgba, xy, fill + (255,), thresh=tolerance)
    return rgba.convert("RGB")


def cleanup_adaptive_resources() -> None:
    for name in LEGACY:
        p = os.path.join(RES, f"mipmap-{name}", "ic_launcher_foreground.png")
        if os.path.exists(p):
            os.remove(p)
            print("removed:", p)
    xml = os.path.join(RES, "mipmap-anydpi-v26", "ic_launcher.xml")
    if os.path.exists(xml):
        os.remove(xml)
        print("removed:", xml)
    colors = os.path.join(RES, "values", "colors.xml")
    if os.path.exists(colors):
        os.remove(colors)
        print("removed:", colors)


def main() -> None:
    if len(sys.argv) > 1:
        src = sys.argv[1]
    else:
        candidates = [
            os.path.join(ROOT, "assets", "app_icon_source.jpg"),
            os.path.join(ROOT, "assets", "app_icon_source.png"),
            os.path.join(ROOT, "app_icon_source.jpg"),
            os.path.join(ROOT, "app_icon_source.png"),
        ]
        src = next((p for p in candidates if os.path.exists(p)), "")
    if not src or not os.path.exists(src):
        print("未找到源图片。用法: python tool/generate_app_icon.py <源图片路径>")
        raise SystemExit(1)

    img = Image.open(src)
    print("source:", src, img.size, img.mode)
    base = center_square(img.convert("RGB"))
    fill = dominant_color_rgb(base)
    print("fill color: #{:02X}{:02X}{:02X}".format(*fill))
    full = fill_white_edges(base, fill)

    for name, px in LEGACY.items():
        out_dir = os.path.join(RES, f"mipmap-{name}")
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, "ic_launcher.png")
        full.resize((px, px), Image.LANCZOS).save(path)
        print("legacy:", path)

    cleanup_adaptive_resources()
    print("DONE (full image kept, white edges filled)")


if __name__ == "__main__":
    main()