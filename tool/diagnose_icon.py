import os
import time

root = r"D:\BabyTime-Android"
print("== assets ==")
assets = os.path.join(root, "assets")
if os.path.isdir(assets):
    items = os.listdir(assets)
    print("count:", len(items))
    for f in items:
        p = os.path.join(assets, f)
        if os.path.isfile(p):
            print(f"  {f}  {os.path.getsize(p)}B  {time.strftime('%m-%d %H:%M', time.localtime(os.path.getmtime(p)))}")
        else:
            print(f"  {f}/  (dir)")
else:
    print("assets missing")

print("\n== 项目内近 3 天图片（排除已知资源/依赖/构建） ==")
now = time.time()
skip = (".dart_tool", "build", ".gradle", ".widget_preview", "nexio-liquid", "miuix-skill", "PubCache")
for dp, dns, fns in os.walk(root):
    if any(s in dp for s in skip):
        dns[:] = []
        continue
    for f in fns:
        if not f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
            continue
        p = os.path.join(dp, f)
        try:
            st = os.stat(p)
        except OSError:
            continue
        if now - st.st_mtime < 3 * 86400:
            print(f"  {time.strftime('%m-%d %H:%M', time.localtime(st.st_mtime))}  {st.st_size}B  {os.path.relpath(p, root)}")

print("\n== 图标资源现状 ==")
res = os.path.join(root, "android", "app", "src", "main", "res")
for d in sorted(os.listdir(res)):
    if d.startswith("mipmap"):
        dp = os.path.join(res, d)
        for f in sorted(os.listdir(dp)):
            p = os.path.join(dp, f)
            st = os.stat(p)
            print(f"  {d}/{f}  {st.st_size}B  {time.strftime('%m-%d %H:%M', time.localtime(st.st_mtime))}")
print("colors.xml:", os.path.exists(os.path.join(res, "values", "colors.xml")))
print("anydpi xml:", os.path.exists(os.path.join(res, "mipmap-anydpi-v26", "ic_launcher.xml")))

print("\n== Manifest 图标引用 ==")
mf = os.path.join(root, "android", "app", "src", "main", "AndroidManifest.xml")
with open(mf, encoding="utf-8") as f:
    for line in f:
        if "icon" in line or "label" in line:
            print("  " + line.rstrip())