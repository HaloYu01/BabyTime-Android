import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/nexio.dart';
import '../../providers/settings_provider.dart';
import '../../services/ai_service.dart';
import '../../services/shoe_size_matcher.dart';
import '../../widgets/nexio_glass.dart';

class ShoeHelperPage extends StatefulWidget {
  const ShoeHelperPage({super.key});

  @override
  State<ShoeHelperPage> createState() => _ShoeHelperPageState();
}

class _ShoeHelperPageState extends State<ShoeHelperPage> {
  double _footLength = 12.0;
  double _allowance = 1.0;
  final _questionCtrl = TextEditingController();
  String? _aiAnswer;
  bool _asking = false;
  String? _askError;

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  ShoeSizeMatch get _match => ShoeSizeMatcher.recommend(
        footLengthCm: _footLength,
        allowanceCm: _allowance,
      );

  void _adjustFoot(double delta) {
    setState(() {
      _footLength = ShoeSizeMatcher.clampFootLength(_footLength + delta);
    });
  }

  String get _ageHint => _footLength < 11
      ? '1~2岁'
      : _footLength < 14
          ? '2~3岁'
          : _footLength < 17
              ? '3~5岁'
              : '5岁以上参考';

  Future<void> _askAi() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.aiConfig.ready) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请先在「设置」中配置 AI 服务的 API Key')));
      return;
    }
    final q = _questionCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _asking = true;
      _askError = null;
    });
    try {
      final answer = await AiService().chat(
        config: settings.aiConfig,
        temperature: 0.5,
        messages: [
          const {
            'role': 'system',
            'content':
                '你是一位婴幼儿足部发育与童鞋选购顾问。宝宝不会表达鞋舒不舒服，选鞋比成人难得多。请给出专业、具体、可执行的选购建议，回答简明扼要，使用简体中文。',
          },
          {
            'role': 'user',
            'content':
                '宝宝脚长 ${_footLength.toStringAsFixed(1)} cm，我计划留 ${_allowance.toStringAsFixed(1)} cm 的成长放量（内长 ${_match.requiredInnerText} cm）。我的问题：$q',
          },
        ],
      );
      if (!mounted) return;
      setState(() {
        _aiAnswer = answer.trim();
        _asking = false;
      });
    } on AiConfigException catch (e) {
      if (!mounted) return;
      setState(() {
        _askError = e.message;
        _asking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _askError = '提问失败，请重试：$e';
        _asking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;

    return NexioPageScaffold(
      title: '选鞋助手',

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
              const NexioCardHeader(title: '第一步：测量脚长'),
              const SizedBox(height: 8),
              Text(
                '让宝宝站立（比坐着量更准），脚跟贴墙，画出脚型后量最长点；建议傍晚量，脚会比早上略大。',
                style: NexioType.body2.copyWith(height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _adjustFoot(-0.1),
                    tooltip: '减少 0.1 cm',
                    icon: const Icon(Icons.remove_circle_outline,
                        color: NexioColors.textAction),
                  ),
                  Text('${_footLength.toStringAsFixed(1)} cm',
                      style: NexioType.t1.copyWith(
                          fontSize: 40, color: NexioColors.primary)),
                  IconButton(
                    onPressed: () => _adjustFoot(0.1),
                    tooltip: '增加 0.1 cm',
                    icon: const Icon(Icons.add_circle_outline,
                        color: NexioColors.primary),
                  ),
                ],
              ),
              Slider(
                value: _footLength,
                min: ShoeSizeMatcher.minFootLength,
                max: ShoeSizeMatcher.maxFootLength,
                divisions: 100,
                label: '${_footLength.toStringAsFixed(1)} cm',
                onChanged: (v) => setState(() => _footLength = v),
              ),
              Center(child: Text(_ageHint, style: NexioType.footnote1)),
            ],
          ),
        ),
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NexioCardHeader(title: '第二步：选择成长放量'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [0.5, 1.0, 1.5].map((v) {
                  final selected = _allowance == v;
                  return NexioChoiceChip(
                    label: '$v cm',
                    selected: selected,
                    onTap: () => setState(() => _allowance = v),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                '学步鞋建议留 0.5~1cm，稳定期 1cm，夏季或宽脚可留 1.5cm。放量太大反而容易摔跤。',
                style: NexioType.body2.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        NexioCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('所需鞋内长约 ${match.requiredInnerText} cm',
                  style: NexioType.body2),
              const SizedBox(height: 4),
              Text(
                '匹配档位：脚长 ${match.rowFootText} 档 · 标准内长 ${match.rowInnerText} cm',
                style: NexioType.footnote1,
                textAlign: TextAlign.center,
              ),
              if (match.note != null) ...[
                const SizedBox(height: 6),
                Text(match.note!,
                    style: NexioType.footnote1
                        .copyWith(color: NexioColors.textAction),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NexioStat(label: '中国码', value: match.row.cnSize),
                  NexioStat(label: 'EU 欧码', value: match.row.euSize),
                  NexioStat(label: 'US 美码', value: match.row.usSize),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '按「所需内长向上取档」匹配（避免脚趾顶鞋）；不同品牌以商品标注的内长为准。',
                style: NexioType.footnote1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NexioCardHeader(title: '尺码对照表'),
              const SizedBox(height: 10),
              Table(
                border: TableBorder.symmetric(
                    inside: const BorderSide(
                        color: NexioColors.divider, width: 0.75)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                        color: NexioColors.surface,
                        borderRadius: BorderRadius.circular(8)),
                    children: _header(['脚长', '内长', '中国码', 'EU', 'US']),
                  ),
                  for (final r in shoeSizeTable)
                    TableRow(children: _cells([
                      r.footLengthCm.toStringAsFixed(1),
                      (r.footLengthCm + 1).toStringAsFixed(1),
                      r.cnSize,
                      r.euSize,
                      r.usSize,
                    ])),
                ],
              ),
            ],
          ),
        ),
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              NexioCardHeader(title: '选购要点'),
              SizedBox(height: 10),
              _Tip(text: '一折：鞋底前1/3可弯折，帮助起步；鞋身别对折'),
              _Tip(text: '二捏：后跟杯要硬，捏不动才稳，保护脚踝'),
              _Tip(text: '三挤：前掌两侧按压不夹脚，留出脚趾活动空间'),
              _Tip(text: '四闻：无明显刺鼻气味，材质透气（网布/头层皮）'),
              _Tip(text: '五试：下午试穿，走路时观察是否拖脚/踮脚'),
            ],
          ),
        ),
        NexioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NexioCardHeader(title: 'AI 选购答疑'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionCtrl,
                      decoration: const InputDecoration(
                          hintText: '如：宝宝扁平足适合什么鞋？'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _asking ? null : _askAi,
                    child: _asking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('提问'),
                  ),
                ],
              ),
              if (_askError != null) ...[
                const SizedBox(height: 10),
                Text(_askError!,
                    style: NexioType.body2.copyWith(color: NexioColors.error)),
              ],
              if (_aiAnswer != null) ...[
                const SizedBox(height: 12),
                Text(_aiAnswer!, style: NexioType.body2.copyWith(height: 1.6)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _header(List<String> texts) => texts
      .map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(t,
                textAlign: TextAlign.center,
                style: NexioType.footnote1
                    .copyWith(color: NexioColors.textSecondary)),
          ))
      .toList();

  List<Widget> _cells(List<String> texts) => texts
      .map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(t,
                textAlign: TextAlign.center, style: NexioType.footnote1),
          ))
      .toList();
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: NexioType.body2),
          Expanded(
              child: Text(text, style: NexioType.body2.copyWith(height: 1.5))),
        ],
      ),
    );
  }
}