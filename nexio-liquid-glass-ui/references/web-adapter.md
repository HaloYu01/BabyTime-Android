# Web / HTML 适配 Web Adapter

把同一套语言搬到网页、Electron、小程序、Flutter Web 等非 Compose 场景。**结论先给**：颜色、几何、间距、字号、动效曲线可以 1:1；玻璃**只能近似**——浏览器没有运行时折射，最高做到"模糊 + 饱和 + 边缘光 + 内阴影"。

## 1 令牌（CSS 变量）

```css
:root {
  --nx-bg: #ffffff;
  --nx-surface: #f4f4f4;
  --nx-surface-container: #ffffff;
  --nx-primary: #3482ff;
  --nx-on-bg: #000000;
  --nx-text-2: rgba(0,0,0,.8);
  --nx-text-summary: rgba(0,0,0,.6);
  --nx-text-action: rgba(0,0,0,.4);
  --nx-divider: #e0e0e0;
  --nx-small-title: #8f9cae;
  --nx-bar: rgba(250,250,250,.5);
  --nx-segment-idle: #ffffff;
  --nx-selector: rgba(0,0,0,.06);
  --nx-shadow: 0 4px 24px rgba(0,0,0,.10);
  --nx-radius-card: 20px;
  --nx-radius-item: 10px;
  --nx-radius-icon: 8px;
  --nx-gap: 10px;
  --nx-ease-out-quart: cubic-bezier(.165,.84,.44,1);
  --nx-ease-out-cubic: cubic-bezier(.215,.61,.355,1);
  --nx-ease-out-quint: cubic-bezier(.23,1,.32,1);
  --nx-ease-page: cubic-bezier(.3,.5,.2,1);
}
html[data-theme="dark"] {
  --nx-bg: #242424;
  --nx-surface: #000000;
  --nx-surface-container: #242424;
  --nx-primary: #277af7;
  --nx-on-bg: rgba(255,255,255,.9);
  --nx-text-2: rgba(255,255,255,.8);
  --nx-text-summary: rgba(255,255,255,.5);
  --nx-text-action: rgba(255,255,255,.4);
  --nx-divider: #393939;
  --nx-bar: rgba(36,36,36,.6);
  --nx-segment-idle: #242424;
  --nx-selector: rgba(255,255,255,.1);
  --nx-shadow: 0 4px 24px rgba(0,0,0,.2);
}
```

## 2 玻璃的 CSS 近似（三件套）

```css
.glass {
  position: relative;
  background: rgba(255,255,255,.28);          /* 有壁纸时更低；深色 rgba(0,0,0,.32) */
  backdrop-filter: blur(12px) saturate(200%) brightness(1.04);
  -webkit-backdrop-filter: blur(12px) saturate(200%) brightness(1.04);
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,.55),        /* 上缘光 */
    inset 0 -1px 0 rgba(0,0,0,.16),             /* 下缘暗 */
    inset 0 0 24px rgba(255,255,255,.06),       /* 内厚度 */
    0 4px 24px rgba(0,0,0,.10);                 /* 外投影 */
  border-radius: 20px;
  overflow: hidden;
}
.glass::before {                               /* 左上方向光 */
  content:""; position:absolute; inset:0; pointer-events:none;
  background: linear-gradient(135deg, rgba(255,255,255,.22), rgba(255,255,255,0) 42%);
  mix-blend-mode: screen;
}
```

参数对照：

| Compose 参数 | CSS 对应 |
|---|---|
| `blur(dp)` 6/12/24 | `blur(6px/12px/24px)`（1dp ≈ 1px @1x；高分屏用 `calc()` 或 rem 视口单位） |
| `saturation` 2.0 | `saturate(200%)` |
| 方向光 | 135° 线性渐变 + `screen` |
| 边缘光 `edge` 60px | `inset` 阴影 1px + 内发光 24px（**做不到** 60px 宽的倒角带，只能压薄） |
| 厚度 `thickness` 96px | 无对应；用内阴影近似 |
| 投影 24dp/10%/y+4 | `0 4px 24px rgba(0,0,0,.1)` |
| `darker 0.2` | `background` 里加黑 alpha |

三点必须知道：
1. `backdrop-filter` **只作用于元素背后的内容**，不支持"折射位移"。想要"透过玻璃看到的东西被扭曲"，只能 `feDisplacementMap` + SVG 滤镜 + 静态纹理，做不到实时。
2. `backdrop-filter` + `overflow:hidden` + 多层嵌套在 Safari / 低端 Android WebView 上会掉帧；一屏 ≤ 3 块。
3. 有 `backdrop-filter` 时**不要再叠不透明底**，那等于没用。

## 3 连续圆角（CSS 做不到就上 SVG）

CSS `border-radius` 是圆弧，HyperOS 是 G2 连续曲率：同样是 20px，圆弧看起来"尖"。

近似方案 A（推荐，成本最低）：半径放大 **1.6–1.8 倍**并轻微收窄容器，视觉接近 squircle：

```css
.card { border-radius: 32px; } /* 真实值 20px → 视觉近似 */
```

方案 B（精确）：超椭圆 `clip-path`。

```css
.squircle-20 {
  clip-path: path("M 20 0 C 20 0 0 0 0 20 L 0 calc(100% - 20) C 0 100% 0 100% 20 100% L calc(100% - 20) 100% C 100% 100% 100% 100% calc(100% - 20) 100% L 100% 20 C 100% 0 100% 0 calc(100% - 20) 0 Z");
}
```
（`path()` 对百分比支持有限，实际项目用 `clip-path: url(#squircle)` 引一段 SVG `path`，或直接把 `<svg>` 当遮罩。）

方案 C（最省事）：用 SVG `<rect rx>` + `paint-order`，或接受圆弧——网页尺度下方案 A 足够。

## 4 悬浮构件

```css
.bottom-bar {
  position: fixed; left: 50%; transform: translateX(-50%);
  bottom: max(calc(env(safe-area-inset-bottom) + 2px), 22px);
  display: flex; gap: 10px;            /* 胶囊与圆钮之间只有 10px */
}
.pill {
  height: 56px; padding: 4px; display: flex; align-items: center;
  border-radius: 999px; background: var(--nx-bar);
  width: calc(21vw * var(--tab-count, 2));   /* 每格占宽 21% */
}
.circle { width: 56px; height: 56px; border-radius: 999px; }
.tab    { height: 48px; flex: 1; border-radius: 999px; font-size: 11px; }
.tab[aria-selected="true"] { background: var(--nx-selector); }
```

顶栏按钮：42px 圆形，图标 24px，`rgba(0,0,0,.85)` / `rgba(255,255,255,.85)` 着色；按下 `transform: scale(.96)`，`transition: transform .18s var(--nx-ease-out-cubic)`。

## 5 滚动即出材质

```js
const bar = document.querySelector('.topbar');
addEventListener('scroll', () => {
  const on = scrollY > 10;                      // 阈值 10px
  bar.style.setProperty('--m', on ? 1 : 0);
}, { passive: true });
```

```css
.topbar {
  --m: 0;
  background: rgba(255,255,255, calc(.72 * var(--m)));
  backdrop-filter: blur(calc(12px * var(--m)));
  transition: background .6s cubic-bezier(.33,1,.68,1), backdrop-filter .4s;
}
.topbar .btn { opacity: calc(.35 + .65 * var(--m)); box-shadow: 0 calc(4px * var(--m)) calc(10px * var(--m)) rgba(0,0,0,.06); }
```

`--m` 用 `@property` 注册成 `<number>` 才能平滑插值（Safari 16+）。

## 6 动效

| 场景 | CSS |
|---|---|
| 卡片入场 | `animation: reveal .26s var(--nx-ease-out-quart) both; animation-delay: calc(.12s + var(--i) * 56ms)` |
| 入场关键帧 | `from { opacity:0; transform: translateY(8px) scale(.97); filter: blur(12px) }` → `to { … }`（`filter: blur` 在低端机贵，可只保留位移+缩放） |
| 文字换字 | 交叉 320ms；`filter: blur(8px)` 140ms 进、180ms 出 |
| morph 展开 | 540ms `var(--nx-ease-out-quart)`；位移 500ms `var(--nx-ease-out-quint)` |
| 收起 | 320ms `var(--nx-ease-out-cubic)` |
| 分段滑块 | `transition: transform .32s cubic-bezier(.34,1.36,.64,1)`（轻过冲，对应弹簧 320） |
| 底栏 tab | `transition: transform .3s cubic-bezier(.34,1.2,.64,1)` |

浏览器里**别做**弹簧的严格复刻（Compose 的 spring 不是三次贝塞尔）；用带轻微过冲的 `cubic-bezier(.34,1.36,.64,1)` 近似即可。

## 7 按压高光（手指/鼠标跟随）

```css
.press { position: relative; overflow: hidden; }
.press::after {
  content:""; position:absolute; left: var(--hx); top: var(--hy);
  width: 180%; aspect-ratio: 1; translate: -50% -50%;
  background: radial-gradient(circle, rgba(255,255,255,.5), transparent 62%);
  opacity: 0; transition: opacity .2s;
}
.press:active::after { opacity: 1; }
```

```js
el.addEventListener('pointerdown', e => {
  const r = el.getBoundingClientRect();
  el.style.setProperty('--hx', `${e.clientX - r.left}px`);
  el.style.setProperty('--hy', `${e.clientY - r.top}px`);
});
```

## 8 可访问性

- `backdrop-filter` 不支持的浏览器（旧 Edge）：`@supports not (backdrop-filter: blur(1px))` 里退回实底 + 描边（等同 `NONE` 档）。
- 减少动效：`@media (prefers-reduced-motion: reduce) { * { animation-duration: .01ms !important; transition-duration: .01ms !important } }`。
- 不要用 `mix-blend-mode` 叠文字；文字始终独立一层，保证对比度。

## 9 小程序 / 原生渲染

| 平台 | 方案 |
|---|---|
| 微信小程序 | `backdrop-filter` 支持不稳定；用"半透明白 + 1px 内描边 + 外投影"实底玻璃（`NONE` 档观感） |
| Flutter | `BackdropFilter` + `ClipRRect`（圆角只能圆弧）；`ImageFilter.blur` 同参数 |
| Electron | 与 Web 相同；窗口透明 + `vibrancy` 只影响窗口底，不影响页面内玻璃 |
| React Native | `expo-blur` / `@react-native-community/blur`；Web 端降级见上 |

## 10 取舍清单（跟用户说明用）

- ✅ 能 1:1：颜色、字号、间距、圆角半径、构件尺寸、动效时长与曲线、深浅两套。
- ⚠️ 近似：模糊、边缘光、内厚度、投影。
- ❌ 做不到：实时折射位移、60px 倒角带、真实屏幕圆角裁切（只能读 `env(safe-area-inset-*)` 与设备尺寸猜）。
- 🚫 不要假装：用一张"玻璃 PNG"贴图会随背景变化穿帮；宁可做扎实的 `FROSTED`（模糊 + 边缘光 + 内阴影）。
