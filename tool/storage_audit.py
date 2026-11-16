import os

ROOT = r"D:\BabyTime-Android"
SKIP = {"__pycache__"}

entries = []
top_agg = {}
for dp, dns, fns in os.walk(ROOT):
    dns[:] = [d for d in dns if d not in SKIP]
    for f in fns:
        p = os.path.join(dp, f)
        try:
            s = os.path.getsize(p)
        except OSError:
            continue
        rel = os.path.relpath(p, ROOT)
        entries.append((s, rel))
        top = rel.split(os.sep)[0]
        top_agg[top] = top_agg.get(top, 0) + s

entries.sort(reverse=True)
total = sum(s for s, _ in entries)
print(f"TOTAL_PROJECT: {total / 1024 / 1024:.2f} MB")
print("\n== 顶层目录聚合 ==")
for k, v in sorted(top_agg.items(), key=lambda kv: -kv[1]):
    print(f"  {v / 1024:10.1f} KB  {k}")

print("\n== 最大文件 TOP 25 ==")
for s, rel in entries[:25]:
    print(f"  {s / 1024:10.1f} KB  {rel}")

print("\n== App 资源明细 ==")
for rel_dir in ("assets", os.path.join("android", "app", "src", "main", "res")):
    base = os.path.join(ROOT, rel_dir)
    if not os.path.isdir(base):
        continue
    agg = 0
    for dp, dns, fns in os.walk(base):
        for f in fns:
            p = os.path.join(dp, f)
            try:
                s = os.path.getsize(p)
            except OSError:
                continue
            agg += s
            if s > 1024:
                print(f"  {s / 1024:8.1f} KB  {os.path.relpath(p, ROOT)}")
    print(f"  -- {rel_dir} 合计: {agg / 1024:.1f} KB")

print("\n== build 产物 ==")
build = os.path.join(ROOT, "build")
if os.path.isdir(build):
    size = 0
    count = 0
    for dp, dns, fns in os.walk(build):
        for f in fns:
            try:
                size += os.path.getsize(os.path.join(dp, f))
            except OSError:
                pass
            count += 1
    print(f"  build/ 存在：{size / 1024 / 1024:.2f} MB，{count} 个文件")
else:
    print("  build/ 不存在（未执行过 flutter build）")