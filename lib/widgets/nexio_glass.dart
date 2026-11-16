import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/nexio.dart';

/// 柔光壁纸底：给玻璃面板提供可被模糊采样的"脚下内容"。
class NexioBackground extends StatelessWidget {
  const NexioBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        ColoredBox(color: NexioColors.background),
        Positioned(
            top: -80,
            right: -60,
            child: _Glow(size: 320, color: NexioColors.glowBlue)),
        Positioned(
            top: 240,
            left: -110,
            child: _Glow(size: 300, color: NexioColors.glowWarm)),
        Positioned(
            bottom: -70,
            right: 30,
            child: _Glow(size: 280, color: NexioColors.glowMint)),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// 模糊面板：仅保留背景模糊（BackdropFilter）+ 低透明度填充。
/// 高光渐变、描边与外投影已移除（玻璃拟态降级为纯模糊）。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.alpha = 1.0,
    this.blur = 12,
    this.fill = NexioColors.blurFill,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double alpha;
  final double blur;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: alpha,
      child: ClipPath(
        clipper: NexioShape.clipper(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: ColoredBox(
            color: fill,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// 圆形玻璃按钮（默认 42dp，命中区 48dp，按压缩放 0.96）。
class GlassCircleButton extends StatefulWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 42,
    this.iconSize = 24,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  @override
  State<GlassCircleButton> createState() => _GlassCircleButtonState();
}

class _GlassCircleButtonState extends State<GlassCircleButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: NexioMotion.press,
              curve: NexioMotion.cubicOut,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: ColoredBox(
                      color: NexioColors.blurFill,
                      child: Center(
                        child: Icon(widget.icon,
                            size: widget.iconSize,
                            color: NexioColors.iconTint),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 20dp 连续曲率的表面卡（Nexio 卡片不投影）。
class NexioCard extends StatelessWidget {
  const NexioCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 20,
    this.color = NexioColors.surfaceContainer,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 0,
      shape: NexioShape.squircle(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 分组小标题（14sp Bold #8F9CAE，12/8 内边距）。
class NexioSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const NexioSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(text, style: NexioType.subtitle), ?trailing],
      ),
    );
  }
}

/// SmallTitle + Card 分组（Miuix 分组模式：小标题在卡片外）。
class NexioSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const NexioSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        NexioSectionTitle(title, trailing: trailing),
        child,
      ],
    );
  }
}

/// 卡片头部行：图标 + 标题 + 尾部操作。
class NexioCardHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  const NexioCardHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: NexioColors.primary),
          const SizedBox(width: 6),
        ],
        Expanded(child: Text(title, style: NexioType.headline1)),
        ?trailing,
      ],
    );
  }
}

/// 统计列：数值 + 说明。
class NexioStat extends StatelessWidget {
  final String label;
  final String value;
  const NexioStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: NexioType.t3.copyWith(color: NexioColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: NexioType.footnote2),
      ],
    );
  }
}

/// 胶囊标签。
class NexioTag extends StatelessWidget {
  final String text;
  final Color color;
  const NexioTag({super.key, required this.text, this.color = NexioColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: NexioType.footnote2
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// 表单行：图标 + 标签 + 值 + 箭头（56dp 行高）。
class NexioFormRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showChevron;
  const NexioFormRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: NexioColors.textAction),
              const SizedBox(width: 12),
            ],
            Text(label, style: NexioType.headline1),
            const Spacer(),
            Text(value,
                style:
                    NexioType.headline2.copyWith(color: NexioColors.primary)),
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: NexioColors.textAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// 卡片入场：260ms 四次缓出，上浮 8dp + 缩放 0.97，首张延迟 120ms，每张 +56ms。
class NexioReveal extends StatefulWidget {
  final Widget child;
  final int index;
  const NexioReveal({super.key, required this.child, this.index = 0});

  @override
  State<NexioReveal> createState() => _NexioRevealState();
}

class _NexioRevealState extends State<NexioReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NexioMotion.reveal,
  );
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: NexioMotion.quartOut);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(NexioMotion.revealDelay(widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _animation.value)),
          child: Transform.scale(
            scale: 0.97 + 0.03 * _animation.value,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 悬浮顶栏：仅保留两侧 42dp 玻璃圆钮（页面标题已在内容区或底栏 tab 中表达）。
class NexioTopBar extends StatelessWidget {
  final Widget? leading;
  final List<Widget> actions;

  const NexioTopBar({
    super.key,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        const Spacer(),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i],
        ],
      ],
    );
  }
}

/// 悬浮底栏：56dp 胶囊 + 10dp 间距 + 单独的 56dp 圆钮。
class NexioBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NexioBarItem(this.icon, this.selectedIcon, this.label);
}

class NexioBottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  final List<NexioBarItem> items;
  final VoidCallback? onTrailingTap;

  const NexioBottomBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.items,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassPanel(
            radius: 28,
            blur: 16,
            fill: NexioColors.barBlurFill,
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(child: _tab(context, i)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GlassCircleButton(
          size: 56,
          iconSize: 26,
          icon: Icons.settings_outlined,
          semanticLabel: '设置',
          onPressed: onTrailingTap,
        ),
      ],
    );
  }

  Widget _tab(BuildContext context, int index) {
    final item = items[index];
    final active = index == selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(index),
      child: AnimatedContainer(
        duration: NexioMotion.tabSwitch,
        curve: NexioMotion.overshoot,
        decoration: BoxDecoration(
          color: active ? NexioColors.selectorFill : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? item.selectedIcon : item.icon,
                size: 24,
                color: active ? NexioColors.primary : NexioColors.iconTint),
            Text(item.label,
                style: NexioType.footnote2.copyWith(
                  fontSize: 11,
                  color:
                      active ? NexioColors.primary : NexioColors.textAction,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

/// 页面骨架：背景层 → 内容层（自动入场动效与分组间距）→ 顶栏层。
/// [title] 为空时不渲染页头（用于与底栏 tab 重名的一级页）。
class NexioPageScaffold extends StatelessWidget {
  const NexioPageScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.children = const [],
    this.bottomInset = 96,
    this.gap = 12,
    this.animateChildren = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final List<Widget> children;
  final double bottomInset;

  /// 子块之间的统一间距（Miuix 分组间距）。
  final double gap;
  final bool animateChildren;

  List<Widget> _buildContent() {
    final content = <Widget>[];
    var revealIndex = 0;
    if (title != null) {
      content.add(NexioReveal(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title!, style: NexioType.t1),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(subtitle!,
                      style: NexioType.body2
                          .copyWith(color: NexioColors.textSummary)),
                ),
            ],
          ),
        ),
      ));
      revealIndex = 1;
    }
    for (var i = 0; i < children.length; i++) {
      if (i > 0) content.add(SizedBox(height: gap));
      content.add(animateChildren
          ? NexioReveal(index: revealIndex + i, child: children[i])
          : children[i]);
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const NexioBackground(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 64, 16, bottomInset),
                children: _buildContent(),
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 16,
            right: 16,
            child: NexioTopBar(leading: leading, actions: actions),
          ),
        ],
      ),
    );
  }
}