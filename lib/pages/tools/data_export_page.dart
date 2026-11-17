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
  DataExportPayload? _payload;
  ExportSaveOutcome? _outcome;
  String? _error;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final payload = await DataExportService.create();
      if (!mounted) return;
      setState(() => _payload = payload);
      final outcome = await DataExportService.saveToUserLocation(payload);
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
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

  Future<void> _saveAgain() async {
    final payload = _payload;
    if (payload == null || _exporting) return;
    setState(() {
      _exporting = true;
      _error = null;
    });
    final outcome = await DataExportService.saveToUserLocation(payload);
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _exporting = false;
    });
  }

  Future<void> _copy() async {
    final payload = _payload;
    if (payload == null) return;
    await Clipboard.setData(ClipboardData(text: payload.json));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('JSON 已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final outcome = _outcome;
    final saved = outcome?.saved == true;
    final cancelled = outcome?.cancelled == true;

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
              Text(
                '保存时请在系统对话框中选择「下载」或「文档」文件夹，保存后即可在手机文件管理器中找到。'
                '文件仅在本机生成，不会上传服务器。',
                style: NexioType.footnote1.copyWith(height: 1.5),
              ),
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
                : const Icon(Icons.save_alt, size: 18),
            label: Text(_exporting ? '生成中…' : '导出并保存到手机'),
          ),
        ),
        if (_error != null)
          NexioCard(
            color: NexioColors.surface,
            child: Text(_error!,
                style: NexioType.body2.copyWith(color: NexioColors.error)),
          ),
        if (payload != null)
          NexioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NexioCardHeader(
                  icon: saved
                      ? Icons.check_circle_outline
                      : cancelled
                          ? Icons.info_outline
                          : Icons.error_outline,
                  title: saved
                      ? '已保存到手机'
                      : cancelled
                          ? '已生成，未保存'
                          : '保存失败',
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NexioStat(label: '睡眠', value: '${payload.sleepCount}'),
                    NexioStat(label: '饮食', value: '${payload.mealCount}'),
                    NexioStat(label: '照片', value: '${payload.photoCount}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NexioStat(label: '成长', value: '${payload.growthCount}'),
                    NexioStat(label: '喂养', value: '${payload.feedingCount}'),
                    NexioStat(label: '总计', value: '${payload.total}'),
                  ],
                ),
                if (saved) ...[
                  const SizedBox(height: 12),
                  Text('保存位置', style: NexioType.footnote1),
                  const SizedBox(height: 2),
                  Text(outcome?.location ?? '你选择的文件夹',
                      style: NexioType.footnote2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('可在文件管理器对应的「下载 / 文档」文件夹中查看。',
                      style: NexioType.footnote2),
                ] else if (cancelled) ...[
                  const SizedBox(height: 12),
                  Text('你取消了保存。可点击「再次保存」重新选择位置，或复制 JSON 内容。',
                      style: NexioType.body2),
                ] else if (outcome?.error != null) ...[
                  const SizedBox(height: 12),
                  Text(outcome!.error!,
                      style: NexioType.body2.copyWith(color: NexioColors.error)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _exporting ? null : _saveAgain,
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('再次保存'),
                  ),
                ),
                const SizedBox(height: 8),
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

        const NexioNoteCard(
          icon: Icons.folder_open,
          text: '若保存对话框未弹出，请改用「复制 JSON 内容」粘贴到笔记或发送到电脑。',
        ),
      ],
    );
  }
}