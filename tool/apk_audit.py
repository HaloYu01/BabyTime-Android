import os
import zipfile

apk = r"D:\BabyTime-Android\app-release.apk"
if not os.path.isfile(apk):
    print("APK not found")
    raise SystemExit(1)

z = zipfile.ZipFile(apk)
infos = z.infolist()
total_raw = sum(i.file_size for i in infos)
total_zip = sum(i.compress_size for i in infos)
print(f"APK: {os.path.getsize(apk) / 1024 / 1024:.2f} MB on disk")
print(f"uncompressed: {total_raw / 1024 / 1024:.2f} MB")
print(f"compressed:   {total_zip / 1024 / 1024:.2f} MB")

abis = {}
for i in infos:
    if i.filename.startswith("lib/"):
        parts = i.filename.split("/")
        if len(parts) > 2:
            abi = parts[1]
            abis[abi] = abis.get(abi, 0) + i.file_size
print("\n== ABI 分布（未压缩） ==")
for k, v in sorted(abis.items(), key=lambda kv: -kv[1]):
    print(f"  {k:14s} {v / 1024 / 1024:7.2f} MB")

groups = {
    "lib/ (native)": 0,
    "assets/flutter_assets/": 0,
    "classes*.dex": 0,
    "res/": 0,
    "META-INF/": 0,
    "other": 0,
}
for i in infos:
    n = i.filename
    if n.startswith("lib/"):
        groups["lib/ (native)"] += i.file_size
    elif n.startswith("assets/flutter_assets/"):
        groups["assets/flutter_assets/"] += i.file_size
    elif n.startswith("classes") and n.endswith(".dex"):
        groups["classes*.dex"] += i.file_size
    elif n.startswith("res/"):
        groups["res/"] += i.file_size
    elif n.startswith("META-INF/"):
        groups["META-INF/"] += i.file_size
    else:
        groups["other"] += i.file_size

print("\n== 内容分类（未压缩） ==")
for k, v in sorted(groups.items(), key=lambda kv: -kv[1]):
    print(f"  {k:24s} {v / 1024 / 1024:7.2f} MB")

print("\n== 最大条目 TOP 12 ==")
for i in sorted(infos, key=lambda x: -x.file_size)[:12]:
    print(f"  {i.file_size / 1024 / 1024:7.2f} MB  {i.filename}")