import os

from PIL import Image

RES = r"D:\BabyTime-Android\android\app\src\main\res"
DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

for name, px in DENSITIES.items():
    folder = os.path.join(RES, f"mipmap-{name}")
    png = os.path.join(folder, "ic_launcher.png")
    if not os.path.isfile(png):
        print(f"{name}: png missing, skip")
        continue

    png_size = os.path.getsize(png)
    img = Image.open(png).convert("RGBA")

    lossless = os.path.join(folder, "ic_launcher_lossless.webp")
    img.save(lossless, "WEBP", lossless=True, quality=100)
    lossless_size = os.path.getsize(lossless)

    lossy = os.path.join(folder, "ic_launcher_lossy.webp")
    img.save(lossy, "WEBP", quality=90)
    lossy_size = os.path.getsize(lossy)

    candidates = [(png_size, "png", png), (lossless_size, "lossless", lossless),
                  (lossy_size, "lossy", lossy)]
    best_size, best_kind, best_path = min(candidates, key=lambda c: c[0])

    print(f"{name}: png={png_size}B lossless={lossless_size}B lossy={lossy_size}B -> {best_kind}")

    if best_kind == "png":
        for p in (lossless, lossy):
            if os.path.exists(p):
                os.remove(p)
        print("  keep png (webp not smaller)")
        continue

    final = os.path.join(folder, "ic_launcher.webp")
    if os.path.exists(final):
        os.remove(final)
    os.replace(best_path, final)
    for p in (lossless, lossy):
        if os.path.exists(p) and p != final:
            os.remove(p)
    os.remove(png)
    print(f"  replaced png with webp ({best_kind}), saved {png_size - best_size}B")

print("\nDone. Verify: mipmap-*/ic_launcher.webp exists, png removed.")