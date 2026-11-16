import 'package:flutter/material.dart';

import '../../core/nexio.dart';
import '../../widgets/nexio_glass.dart';
import '../feeding/feeding_page.dart';
import '../gallery/gallery_page.dart';
import '../growth/growth_page.dart';
import '../shoes/shoe_helper_page.dart';
import 'data_export_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return NexioPageScaffold(
      children: [
        NexioSection(
          title: '宝宝成长',
          child: NexioCard(
            onTap: () => _push(context, const GrowthPage()),
            child: const _ToolRow(
              icon: Icons.trending_up,
              title: '成长记录',
              desc: '记录身高、体重、头围，查看生长曲线与累计变化。',
            ),
          ),
        ),
        NexioSection(
          title: '记录与照顾',
          child: NexioCard(
            onTap: () => _push(context, const FeedingPage()),
            child: const _ToolRow(
              icon: Icons.timer_outlined,
              title: '喂养计时器',
              desc: '母乳左/右侧或瓶喂计时，自动保存每次喂养记录。',
            ),
          ),
        ),
        NexioSection(
          title: '选购与影像',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 152,
                  child: _SmallCard(
                    icon: Icons.do_not_step_outlined,
                    title: '选鞋助手',
                    desc: '脚长 0.1cm 精度，推荐鞋码',
                    onTap: () => _push(context, const ShoeHelperPage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 152,
                  child: _SmallCard(
                    icon: Icons.photo_library_outlined,
                    title: '照片记录',
                    desc: '去背景留主体，成长纪念',
                    onTap: () => _push(context, const GalleryPage()),
                  ),
                ),
              ),
            ],
          ),
        ),
        NexioSection(
          title: '数据与安全',
          child: NexioCard(
            onTap: () => _push(context, const DataExportPage()),
            child: const _ToolRow(
              icon: Icons.file_upload_outlined,
              title: '数据备份与导出',
              desc: '一键导出全部本地记录为 JSON 文件，不上传服务器。',
            ),
          ),
        ),
        NexioCard(
          color: NexioColors.surface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline,
                  size: 18, color: NexioColors.textAction),
              const SizedBox(width: 10),
              Expanded(
                child: Text('所有记录仅保存在本机；导出文件由你主动生成与分享。',
                    style: NexioType.body2.copyWith(height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _ToolRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: NexioColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: NexioColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: NexioType.headline1),
              const SizedBox(height: 4),
              Text(desc, style: NexioType.body2.copyWith(height: 1.5)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right,
            size: 20, color: NexioColors.textAction),
      ],
    );
  }
}

class _SmallCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _SmallCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NexioColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: NexioColors.primary),
          ),
          const Spacer(),
          Text(title, style: NexioType.headline1),
          const SizedBox(height: 2),
          Text(desc,
              style: NexioType.footnote2.copyWith(height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}