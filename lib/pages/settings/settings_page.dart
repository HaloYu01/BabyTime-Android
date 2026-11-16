import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/constants.dart';
import '../../core/nexio.dart';
import '../../models/baby_profile.dart';
import '../../providers/baby_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_store.dart';
import '../../services/update_service.dart';
import '../../widgets/nexio_glass.dart';
import '../../widgets/nexio_pickers.dart';
import 'changelog_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _removeBgCtrl = TextEditingController();
  String _gender = '男';
  String _feeding = '母乳';
  String _region = '北京';
  String _presetId = 'zhipu';
  DateTime _birthday = DateTime.now().subtract(const Duration(days: 180));
  bool _initialized = false;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFields());
  }

  void _initFields() {
    final profile = context.read<BabyProvider>().profile;
    final ai = context.read<SettingsProvider>();
    setState(() {
      _nameCtrl.text = profile.name;
      _gender = profile.gender;
      _feeding = profile.feedingType;
      _region = profile.region;
      _birthday = profile.birthday;
      _presetId = ai.aiConfig.presetId;
      _apiKeyCtrl.text = ai.aiConfig.apiKey;
      _baseUrlCtrl.text = ai.aiConfig.baseUrl;
      _modelCtrl.text = ai.aiConfig.model;
      _removeBgCtrl.text = ai.removeBgKey;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _removeBgCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _checkUpdate() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final result = await UpdateService.check();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    if (result.status == UpdateStatus.hasUpdate) {
      await _showUpdateDialog(result);
    } else if (result.status == UpdateStatus.upToDate) {
      _toast('已是最新版本 v${result.currentVersion}');
    } else if (result.status == UpdateStatus.noPublicRelease) {
      _toast('仓库暂未发布正式版本（当前 v${result.currentVersion}）');
    } else {
      _toast(result.error ?? '检查失败，请稍后重试');
    }
  }

  Future<void> _showUpdateDialog(UpdateCheckResult result) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('发现新版本 v${result.latestVersion}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本 v${result.currentVersion}',
                style: NexioType.footnote1),
            if (result.publishedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '发布于 ${result.publishedAt!.year}-${result.publishedAt!.month.toString().padLeft(2, '0')}-${result.publishedAt!.day.toString().padLeft(2, '0')}',
                style: NexioType.footnote1,
              ),
            ],
            if (result.notes != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(result.notes!,
                      style: NexioType.body2.copyWith(height: 1.5)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(UpdateRepository.repoUrl,
                style: NexioType.footnote2
                    .copyWith(color: NexioColors.textAction)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('去下载'),
          ),
        ],
      ),
    );
    if (go == true) {
      await _openUrl(result.releaseUrl ?? UpdateRepository.releasesUrl);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      _toast('无法打开浏览器，链接已复制到剪贴板');
    }
  }

  Future<void> _pickBirthday() async {
    final d = await showNexioDatePicker(
      context,
      initialDate: _birthday,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      lastDate: DateTime.now(),
      title: '选择出生日期',
    );
    if (d != null) setState(() => _birthday = d);
  }

  void _saveBaby() {
    context.read<BabyProvider>().update(BabyProfile(
          name: _nameCtrl.text.trim().isEmpty ? '宝宝' : _nameCtrl.text.trim(),
          gender: _gender,
          birthday: _birthday,
          feedingType: _feeding,
          region: _region,
        ));
    _toast('宝宝信息已保存');
  }

  void _saveAi() {
    context.read<SettingsProvider>().updateAiConfig(AiConfig(
          presetId: _presetId,
          baseUrl: _baseUrlCtrl.text.trim(),
          apiKey: _apiKeyCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
        ));
    _toast('AI 配置已保存');
  }

  void _saveRemoveBg() {
    context.read<SettingsProvider>().updateRemoveBgKey(_removeBgCtrl.text.trim());
    _toast('去背景配置已保存');
  }

  int get _monthsOld {
    final now = DateTime.now();
    var months = (now.year - _birthday.year) * 12 +
        now.month -
        _birthday.month;
    if (now.day < _birthday.day) months--;
    return months < 0 ? 0 : months;
  }

  Widget _saveButton(String label, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      );

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: const [
            NexioBackground(),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    final regions = regionDietTraits.keys.toList()..sort();

    return NexioPageScaffold(
      title: '设置',

      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      children: [
        NexioSection(
          title: '宝宝档案',
          child: NexioCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '宝宝名字'),
                ),
                const SizedBox(height: 12),
                Material(
                  color: NexioColors.surface,
                  shape: NexioShape.squircle(12),
                  clipBehavior: Clip.antiAlias,
                  child: NexioFormRow(
                    label: '出生日期',
                    value: '${_birthday.year}/${_birthday.month}/${_birthday.day}'
                        '（$_monthsOld个月）',
                    onTap: _pickBirthday,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NexioDropdownField<String>(
                        label: '性别',
                        value: _gender,
                        items: const ['男', '女'],
                        itemLabel: (v) => v,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NexioDropdownField<String>(
                        label: '喂养方式',
                        value: _feeding,
                        items: const ['母乳', '奶粉', '混合喂养', '辅食为主'],
                        itemLabel: (v) => v,
                        onChanged: (v) => setState(() => _feeding = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NexioDropdownField<String>(
                  label: '所在地区',
                  value: _region,
                  items: regions,
                  itemLabel: (r) => r,
                  helperText: '影响饮食建议的地域差异分析',
                  onChanged: (v) => setState(() => _region = v),
                ),
                const SizedBox(height: 16),
                _saveButton('保存宝宝档案', _saveBaby),
              ],
            ),
          ),
        ),
        NexioSection(
          title: 'AI 服务配置',
          child: NexioCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '用于睡眠预测与饮食建议。兼容 OpenAI 格式的服务均可（智谱 GLM、DeepSeek、通义千问、Kimi 等）。',
                  style: NexioType.body2,
                ),
                const SizedBox(height: 8),
                Text(
                  '提示：免费模型（如 glm-4-flash）的指令遵循能力有限，饮食建议对月龄约束的把握可能不够精确。'
                  'App 已内置月龄安全规则校验并自动过滤不适龄建议；如对准确性要求高，建议切换 glm-4-plus 或 deepseek-chat。',
                  style: NexioType.footnote1.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                NexioDropdownField<String>(
                  label: '服务商',
                  value: _presetId,
                  items: aiPresets.map((p) => p.id).toList(),
                  itemLabel: (id) =>
                      aiPresets.firstWhere((p) => p.id == id).name,
                  onChanged: (v) {
                    setState(() {
                      _presetId = v;
                      final preset = aiPresets.firstWhere((p) => p.id == v);
                      _baseUrlCtrl.text = preset.baseUrl;
                      _modelCtrl.text = preset.defaultModel;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'API Key（必填）', helperText: '仅在本地存储，不会上传'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _baseUrlCtrl,
                  decoration: const InputDecoration(
                      labelText: '接口地址',
                      helperText: '如 https://open.bigmodel.cn/api/paas/v4'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                      labelText: '模型名称', helperText: '如 glm-4-flash（智谱免费模型）'),
                ),
                const SizedBox(height: 16),
                _saveButton('保存 AI 配置', _saveAi),
              ],
            ),
          ),
        ),
        NexioSection(
          title: '去背景服务',
          child: NexioCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使用 remove.bg 去除照片背景（免费额度每月 50 张），到官网注册即可获取 API Key。',
                  style: NexioType.body2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _removeBgCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'remove.bg API Key'),
                ),
                const SizedBox(height: 16),
                _saveButton('保存去背景配置', _saveRemoveBg),
              ],
            ),
          ),
        ),
        NexioSection(
          title: '关于',
          child: NexioCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'BabyTime v${AppInfo.version}\nAI 夜醒预测 · 地域饮食建议 · 选鞋助手 · 照片成长记录\n\n'
                    'AI 预测仅供参考，不能替代专业医疗建议；如宝宝持续异常哭闹、睡眠严重紊乱，请及时就医。',
                    style: NexioType.body2.copyWith(height: 1.6),
                  ),
                ),
                const Divider(),
                NexioFormRow(
                  icon: Icons.history,
                  label: '更新日志',
                  value: 'v${AppInfo.version}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangelogPage()),
                  ),
                ),
                const Divider(),
                NexioFormRow(
                  icon: Icons.system_update_outlined,
                  label: '检查更新',
                  value: _checkingUpdate ? '检查中…' : '检查',
                  onTap: _checkingUpdate ? null : _checkUpdate,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}