import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/nexio.dart';
import '../../services/data_export_service.dart';
import '../../widgets/nexio_glass.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  bool _exporting = false;
  DataExportResult? _result;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final result = await DataExportService.exportAll();
      if (!mounted) return;
      setState(() {
        _result = result;
        _exporting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '导出失败：$e';
        _exporting = false;
      });
    }
  }

  Future<void> _copy() async {
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result.json));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('JSON 已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return NexioPageScaffold(
      title: '数据备份与导出',
      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      children: [
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NexioCardHeader(
                  icon: Icons.shield_outlined, title: '导出说明'),
              const SizedBox(height: 8),
              Text('导出内容：睡眠、饮食、照片记录、成长数据、喂养记录。',
                  style: NexioType.body2),
              const SizedBox(height: 4),
              Text('文件仅在你本机生成，不会上传服务器；请妥善保管。',
                  style: NexioType.footnote1),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_upload_outlined, size: 18),
            label: Text(_exporting ? '生成中…' : '生成导出文件'),
          ),
        ),
        if (_error != null)
          NexioCard(
            color: NexioColors.surface,
            child: Text(_error!,
                style: NexioType.body2.copyWith(color: NexioColors.error)),
          ),
        if (result != null)
          NexioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NexioCardHeader(
                    icon: Icons.check_circle_outline, title: '导出完成'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NexioStat(label: '睡眠', value: '${result.sleepCount}'),
                    NexioStat(label: '饮食', value: '${result.mealCount}'),
                    NexioStat(label: '照片', value: '${result.photoCount}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NexioStat(label: '成长', value: '${result.growthCount}'),
                    NexioStat(label: '喂养', value: '${result.feedingCount}'),
                    NexioStat(label: '总计', value: '${result.total}'),
                  ],
                ),
                const SizedBox(height: 12),
                Text('文件路径', style: NexioType.footnote1),
                const SizedBox(height: 2),
                Text(result.filePath,
                    style: NexioType.footnote2,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('复制 JSON 内容'),
                  ),
                ),
              ],
            ),
          ),
        NexioCard(
          color: NexioColors.surface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: NexioColors.textAction),
              const SizedBox(width: 10),
              Expanded(
                child: Text('导出文件保存在应用文档目录，可通过系统文件管理或分享应用访问。',
                    style: NexioType.body2.copyWith(height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}