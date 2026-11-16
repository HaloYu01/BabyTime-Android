import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/nexio.dart';
import '../../models/changelog.dart';
import '../../services/changelog_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nexio_glass.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  late final Future<List<ChangelogEntry>> _future = ChangelogService.load();

  @override
  Widget build(BuildContext context) {
    return NexioPageScaffold(
      title: '更新日志',
      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      children: [
        FutureBuilder<List<ChangelogEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const NexioCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            final entries = snapshot.data ?? const <ChangelogEntry>[];
            if (entries.isEmpty) {
              return const NexioCard(
                child: EmptyState(icon: Icons.history, text: '暂无更新记录'),
              );
            }
            final current =
                ChangelogParser.findCurrent(entries, AppInfo.version);
            final history = entries
                .where((e) => e.version != AppInfo.version)
                .toList(growable: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current != null)
                  _VersionCard(entry: current, isCurrent: true)
                else
                  _MissingCurrentCard(),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const NexioSectionTitle('历史版本'),
                  for (final entry in history) ...[
                    _VersionCard(entry: entry, isCurrent: false),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MissingCurrentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NexioCard(
      color: NexioColors.tertiaryContainer,
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: NexioColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('当前版本 v${AppInfo.version} 暂无更新记录',
                style: NexioType.body2),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatefulWidget {
  final ChangelogEntry entry;
  final bool isCurrent;
  const _VersionCard({required this.entry, required this.isCurrent});

  @override
  State<_VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends State<_VersionCard> {
  late bool _expanded = widget.isCurrent;

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final date =
        '${entry.date.year}-${_two(entry.date.month)}-${_two(entry.date.day)}';
    return NexioCard(
      color: widget.isCurrent
          ? NexioColors.tertiaryContainer
          : NexioColors.surfaceContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('v${entry.version}', style: NexioType.t3),
                          if (widget.isCurrent) ...[
                            const SizedBox(width: 8),
                            const NexioTag(text: '当前版本'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('$date · ${entry.items.length} 项更新',
                          style: NexioType.footnote1),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: NexioColors.textAction,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: NexioMotion.cubicOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        for (final item in entry.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ItemRow(item: item),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ChangelogItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (item.scope != null) '影响：${item.scope}',
      if (item.ref != null) '关联：${item.ref}',
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NexioTag(text: item.type.label, color: _typeColor(item.type)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: NexioType.body2.copyWith(
                      color: NexioColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              if (item.detail != null) ...[
                const SizedBox(height: 2),
                Text(item.detail!, style: NexioType.footnote2),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(meta,
                    style: NexioType.footnote2
                        .copyWith(color: NexioColors.textAction)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Color _typeColor(ChangelogType type) {
    switch (type) {
      case ChangelogType.added:
        return NexioColors.primary;
      case ChangelogType.changed:
        return const Color(0xFF30A46C);
      case ChangelogType.fixed:
        return const Color(0xFFF5A524);
      case ChangelogType.removed:
        return NexioColors.textSecondary;
      case ChangelogType.security:
        return NexioColors.error;
    }
  }
}