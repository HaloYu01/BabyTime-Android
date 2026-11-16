#!/usr/bin/env python3
"""扫描 NexioSchedule 源码里的关键 UI 常量，与 skill 中记录的值比对。

用途：项目更新后快速判断「规范有没有变」。只读源码，不改任何文件。

用法：
    python scripts/snapshot-tokens.py "D:\\work\\NexioSchedule"
    python scripts/snapshot-tokens.py "D:\\work\\NexioSchedule" --json
    python scripts/snapshot-tokens.py "D:\\work\\NexioSchedule" --strict   # 有漂移时退出码 1
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Anchor:
    label: str
    file_key: str          # 相对路径中必须包含的片段（用 / 分隔）
    pattern: str           # 需含 1..n 个捕获组
    expected: tuple[str, ...]
    note: str = ""


# file_key 取各源文件独有的路径片段，避免同名文件冲突
ANCHORS: tuple[Anchor, ...] = (
    # ---- 顶栏 / 页面 ----
    Anchor("顶栏折叠高", "miuix\\src\\commonMain\\kotlin\\top\\yukonga\\miuix\\kmp\\basic\\TopAppBar.kt",
           r"val CollapsedHeight = (\d+(?:\.\d+)?)\.dp", ("52",), "TopAppBarDefaults"),
    Anchor("顶栏标题内边距", "basic\\TopAppBar.kt",
           r"val TitlePadding = (\d+(?:\.\d+)?)\.dp", ("26",)),
    Anchor("顶栏折叠加高", "layout\\CollapsibleTopAppBar.kt",
           r"val CollapsedHeight = (\d+(?:\.\d+)?)\.dp", ("52",)),
    Anchor("材质触发阈值", "layout\\TopBarMaterial.kt",
           r"val TopBarMaterialThreshold: Dp = (\d+(?:\.\d+)?)\.dp", ("10",)),
    Anchor("文档页糊带基高", "components\\DocumentPageScaffold.kt",
           r"val PageBlurBaseHeight: Dp = (\d+(?:\.\d+)?)\.dp", ("72",)),
    Anchor("文档页头部加高", "components\\DocumentPageScaffold.kt",
           r"val HeaderComponentBlurExtra: Dp = (\d+(?:\.\d+)?)\.dp", ("72",)),

    # ---- 通用行 / 卡片 / 小标题 ----
    Anchor("行内边距", "basic\\Component.kt",
           r"val InsideMargin = PaddingValues\((\d+(?:\.\d+)?)\.dp\)", ("16",)),
    Anchor("卡片圆角", "basic\\Card.kt",
           r"val CornerRadius = (\d+(?:\.\d+)?)\.dp", ("20",)),
    Anchor("小标题内边距", "basic\\SmallTitle.kt",
           r"val InsideMargin = PaddingValues\((\d+(?:\.\d+)?)\.dp, (\d+(?:\.\d+)?)\.dp\)",
           ("12", "8"), "水平, 垂直"),

    # ---- 分段 / 底栏 / 滑块 ----
    Anchor("分段容器高", "components\\CapsuleSegmentedControl.kt",
           r"containerHeight: Dp = (\d+(?:\.\d+)?)\.dp", ("42",)),
    Anchor("底栏容器高", "components\\LiquidBottomTabs.kt",
           r"containerHeight: Dp = (\d+(?:\.\d+)?)\.dp", ("56",)),
    Anchor("底栏滑块高", "components\\LiquidBottomTabs.kt",
           r"selectorHeight: Dp = (\d+(?:\.\d+)?)\.dp", ("48",)),
    Anchor("底栏圆钮直径", "components\\ScheduleBottomBar.kt",
           r"val BOTTOM_BAR_CIRCLE = (\d+(?:\.\d+)?)\.dp", ("56",)),
    Anchor("底栏间距", "components\\ScheduleBottomBar.kt",
           r"val BOTTOM_BAR_GAP = (\d+(?:\.\d+)?)\.dp", ("10",)),
    Anchor("底栏每格占宽", "components\\ScheduleBottomBar.kt",
           r"const val TAB_WIDTH_FRACTION = (\d+(?:\.\d+)?)f", ("0.21",)),
    Anchor("滑块左右内缩", "components\\CapsuleSlider.kt",
           r"val Inset = (\d+(?:\.\d+)?)\.dp", ("0.5",)),
    Anchor("滑块上下内缩", "components\\CapsuleSlider.kt",
           r"val VerticalInset = (\d+(?:\.\d+)?)\.dp", ("8",)),
    Anchor("拖尾上限", "components\\CapsuleSlider.kt",
           r"val TrailMax = (\d+(?:\.\d+)?)\.dp", ("20",)),
    Anchor("按压收缩", "components\\CapsuleSlider.kt",
           r"val PressShrink = (\d+(?:\.\d+)?)\.dp", ("2",)),
    Anchor("拖尾增益", "components\\CapsuleSlider.kt",
           r"const val TrailGain: Float = (\d+(?:\.\d+)?)f", ("4",)),
    Anchor("拖尾低通", "components\\CapsuleSlider.kt",
           r"const val TrailSmoothing: Float = (\d+(?:\.\d+)?)f", ("0.55",)),
    Anchor("抓滑块判定", "components\\CapsuleSlider.kt",
           r"const val GrabHalfWidthRatio: Float = (\d+(?:\.\d+)?)f", ("0.55",)),
    Anchor("快甩阈值", "components\\CapsuleSlider.kt",
           r"val FlingVelocityDpPerSecond = (\d+(?:\.\d+)?)\.dp", ("420",)),
    Anchor("滑块按压缩放", "components\\CapsuleSlider.kt",
           r"const val PressScale: Float = (\d+)f / (\d+)f", ("78", "56"), "分子, 分母"),

    # ---- 顶部按钮 / 高光 ----
    Anchor("圆钮直径", "ui\\basic\\LiquidTopBarButton.kt",
           r"buttonHeight: Dp = (\d+(?:\.\d+)?)\.dp", ("42",)),
    Anchor("高光弹簧阻尼", "liquidglass\\InteractiveHighlight.kt",
           r"const val SPRING_DAMPING_RATIO = (\d+(?:\.\d+)?)f", ("0.5",)),
    Anchor("高光弹簧刚度", "liquidglass\\InteractiveHighlight.kt",
           r"const val SPRING_STIFFNESS = (\d+(?:\.\d+)?)f", ("300",)),

    # ---- 动效 ----
    Anchor("文字交叉时长", "text\\TextMotion.kt",
           r"private const val TEXT_MOTION_MILLIS = (\d+)", ("320",)),
    Anchor("文字模糊攻击", "text\\TextMotion.kt",
           r"private const val TEXT_MOTION_BLUR_ATTACK_MILLIS = (\d+)", ("140",)),
    Anchor("文字模糊释放", "text\\TextMotion.kt",
           r"private const val TEXT_MOTION_BLUR_RELEASE_MILLIS = (\d+)", ("180",)),
    Anchor("文字模糊半径", "text\\TextMotion.kt",
           r"private val TEXT_MOTION_BLUR = (\d+(?:\.\d+)?)\.dp", ("8",)),
    Anchor("文字并发上限", "text\\TextMotion.kt",
           r"private const val MAX_CONCURRENT = (\d+)", ("48",)),
    Anchor("卡片入场时长", "components\\CardReveal.kt",
           r"const val ENTER_MILLIS = (\d+)", ("260",)),
    Anchor("卡片退场时长", "components\\CardReveal.kt",
           r"const val EXIT_MILLIS = (\d+)", ("200",)),
    Anchor("卡片首张延迟", "components\\CardReveal.kt",
           r"const val START_DELAY_MILLIS = (\d+)L", ("120",)),
    Anchor("卡片逐张延迟", "components\\CardReveal.kt",
           r"const val STEP_DELAY_MILLIS = (\d+)L", ("56",)),
    Anchor("卡片上浮位移", "components\\CardReveal.kt",
           r"const val OFFSET_DP = (\d+(?:\.\d+)?)f", ("8",)),
    Anchor("卡片起始缩放", "components\\CardReveal.kt",
           r"const val SCALE_FROM = (\d+(?:\.\d+)?)f", ("0.97",)),
    Anchor("卡片入场模糊", "components\\CardReveal.kt",
           r"const val BLUR_DP = (\d+(?:\.\d+)?)f", ("12",)),
    Anchor("morph 展开", "motion\\MorphTransition.kt",
           r"const val MORPH_OPEN_MILLIS = (\d+)", ("540",)),
    Anchor("morph 位移", "motion\\MorphTransition.kt",
           r"const val TRANS_OPEN_MILLIS = (\d+)", ("500",)),
    Anchor("morph 收起", "motion\\MorphTransition.kt",
           r"const val MORPH_EXIT_MILLIS = (\d+)", ("320",)),
    Anchor("拖拽拉伸比", "interactive\\DropdownPanelDragSelect.kt",
           r"const val GlassDragStretchRatio = (\d+(?:\.\d+)?)f", ("0.012",)),
    Anchor("拖拽位移阻尼", "interactive\\DropdownPanelDragSelect.kt",
           r"const val GlassDragTranslationDamping = (\d+(?:\.\d+)?)f", ("0.032",)),

    # ---- 平板 ----
    Anchor("平板侧栏轨宽", "components\\TabletNavPadding.kt",
           r"val TabletNavIconRailWidth = (\d+(?:\.\d+)?)\.dp", ("84",)),
    Anchor("平板侧栏左缘", "components\\TabletNavPadding.kt",
           r"val TabletNavSideInset = (\d+(?:\.\d+)?)\.dp", ("12",)),
    Anchor("平板展开占比", "components\\TabletNavPadding.kt",
           r"const val TabletNavSideWidthFraction = (\d+(?:\.\d+)?)f", ("0.22",)),
    Anchor("平板展开最小宽", "components\\TabletNavPadding.kt",
           r"val TabletNavSideExpandedMinWidth = (\d+(?:\.\d+)?)\.dp", ("200",)),

    # ---- 内容卡 ----
    Anchor("内容卡圆角", "classschedule\\CourseCard.kt",
           r"cardCornerRadius: Float = (\d+(?:\.\d+)?)f", ("10",)),
)


def build_index(root: Path) -> dict[str, list[Path]]:
    index: dict[str, list[Path]] = {}
    for p in root.rglob("*"):
        if p.is_file() and p.suffix == ".kt":
            index.setdefault(p.name, []).append(p)
    for v in index.values():
        v.sort(key=lambda p: len(p.parts))
    return index


def find_file(index: dict[str, list[Path]], key: str, cache: dict[str, Path | None]) -> Path | None:
    if key in cache:
        return cache[key]
    parts = [p for p in key.replace("/", "\\").split("\\") if p]
    name = parts[-1]
    dirs = [p.lower() for p in parts[:-1]]
    for p in index.get(name, []):
        if dirs:
            parent = [x.lower() for x in p.parent.parts]
            if parent[-len(dirs):] != dirs:
                continue
        cache[key] = p
        return p
    cache[key] = None
    return None


def norm(s: str) -> str:
    try:
        f = float(s)
        return f"{f:g}"
    except ValueError:
        return s.strip().lower()


def scan(root: Path) -> list[dict]:
    cache: dict[str, Path | None] = {}
    index = build_index(root)
    rows: list[dict] = []
    for a in ANCHORS:
        exp = " / ".join(a.expected)
        path = find_file(index, a.file_key, cache)
        if path is None:
            rows.append({"label": a.label, "value": None, "expected": exp,
                         "status": "missing-file", "file": a.file_key})
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        m = re.search(a.pattern, text, re.MULTILINE)
        if not m:
            rows.append({"label": a.label, "value": None, "expected": exp,
                         "status": "no-match", "file": str(path.relative_to(root))})
            continue
        got = tuple(g or "" for g in m.groups())
        ok = len(got) == len(a.expected) and all(norm(x) == norm(y) for x, y in zip(got, a.expected))
        rows.append({
            "label": a.label,
            "value": " / ".join(got),
            "expected": exp,
            "status": "ok" if ok else "drift",
            "file": str(path.relative_to(root)),
            "note": a.note,
        })
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description="扫描 NexioSchedule UI 常量并与 skill 记录值比对")
    ap.add_argument("root", help="NexioSchedule 源码根目录")
    ap.add_argument("--json", action="store_true", help="输出 JSON")
    ap.add_argument("--strict", action="store_true", help="有漂移/缺文件时退出码 1")
    args = ap.parse_args()

    root = Path(args.root).expanduser().resolve()
    if not root.is_dir():
        print(f"目录不存在：{root}", file=sys.stderr)
        return 2

    rows = scan(root)

    if args.json:
        print(json.dumps(rows, ensure_ascii=False, indent=2))
    else:
        w = max(len(r["label"]) for r in rows) + 2
        print(f"{'项'.ljust(w)} {'当前值':<16} {'skill 记录':<16} 状态")
        print("-" * (w + 46))
        icon = {"ok": "OK", "drift": "!! 漂移", "missing-file": "?? 缺文件", "no-match": "?? 未匹配"}
        for r in rows:
            print(f"{r['label'].ljust(w)} {str(r['value'] or '-'):<16} "
                  f"{r['expected']:<16} {icon[r['status']]}")
            if r["status"] in ("drift", "missing-file", "no-match"):
                print(f"    {r['file']}")
        bad = sum(1 for r in rows if r["status"] != "ok")
        print(f"\n共 {len(rows)} 项，正常 {len(rows) - bad}，需复核 {bad}")
        if bad:
            print("→ 需复核项对应 references/design-tokens.md、components.md、motion.md、glass-material.md")

    if args.strict and any(r["status"] != "ok" for r in rows):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
