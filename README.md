# BabyTime 育儿助手

一款面向新手父母的育儿辅助 App（Flutter / Android 单平台）。

- 版本：**1.0.2+3**（语义化版本 `版本名+构建号`，详见 [CHANGELOG.md](CHANGELOG.md)）
- 界面：Nexio 设计规范（Miuix 风格设计令牌 + 纯模糊玻璃构件），数据全部本地存储

## 功能

### 1. 首页「今日概览」
- 聚合今晚睡眠预测（预计夜醒次数 / 概率 / 哭闹风险 / 置信度）与今日饮食记录数，点击直达睡眠或饮食页
- 「快速记录」：一个主按钮选择记录睡眠或饮食
- 「今日育儿贴士」：按宝宝月龄阶段每日轮换的本地贴士（无需联网、无需 AI）

### 2. 睡眠预测（核心）
记录宝宝每次的入睡时间、最终醒来时间、夜醒次数和哭闹情况，结合最近 7 天作息：
- **本地可解释预测器**：月龄基线 + 近 3 日回归 + 饮食×睡眠交互项，输出夜醒次数、概率、哭闹风险与 Top5 归因
- **AI 深度分析**：点击后调用所配置的 OpenAI 兼容服务，给出今晚夜醒时间点预测、哭闹高风险时段与可执行改善建议
- 记录可选字段：入睡耗时、白天活动、健康事件

### 3. 地域饮食建议
结合宝宝所在地区的饮食差异（内置 28 个省市的饮食特征库，如面食/米饭、口味浓淡、夜宵文化等）与最近的饮食、睡眠记录，AI 生成：
- 今日各餐的具体建议
- 饮食对今晚睡眠质量的影响分析

食物类型由家长**自由填写**，自动提取面食 / 米类 / 奶制品 / 蔬果 / 蛋白 / 含糖 / 胀气 / 致敏 / 液体等特征参与建模；记录可选份量与餐后反应（胀气 / 吐奶 / 疑似过敏 / 便秘）。

### 4. 喂养计时器
- 母乳左/右侧与瓶喂计时
- 计时结束自动保存喂养记录（含奶量）

### 5. 成长记录
- 记录身高 / 体重 / 头围
- 查看生长曲线与累计变化

### 6. 宝宝选鞋助手
- 脚长测量指导 + 滑块输入
- 成长放量选择（学步鞋 0.5~1cm）→ 推荐鞋内长
- 中国码 / EU / US 尺码对照表（10.5~20cm 全覆盖）
- 「一折二捏三挤四闻五试」选购要点
- AI 选购答疑（如「宝宝扁平足适合什么鞋」）

### 7. 照片成长记录
- 拍照 / 相册导入，按日期归档
- 一键 **AI 去背景**（remove.bg），抠图/原图切换查看
- 照片保存上限 1600px / 质量 80，删除记录时同步清理原图与抠图文件

### 8. 数据备份与导出
- 一键导出全部本地记录为 JSON 文件（不上传服务器），支持复制内容

### 9. 检查更新
- 「关于」页手动检查：读取本仓库的 GitHub Release / Tag 判断新版本，可跳转下载页；无公开版本时提示当前为开发版

## AI 服务配置（设置页）

所有 AI 能力走 **OpenAI 兼容格式**，无需改代码即可切换：

| 服务商 | 默认模型 | 说明 |
|---|---|---|
| 智谱 GLM | glm-4-flash | 有免费模型，推荐起步 |
| DeepSeek | deepseek-chat | 便宜好用 |
| 通义千问 | qwen-plus | 阿里云 |
| Kimi | moonshot-v1-8k | 长文本 |
| 自定义 | - | 任意 OpenAI 兼容接口 |

到对应平台申请 API Key，在 App 内「设置」填入即可（仅本地存储）。

去背景功能使用 [remove.bg](https://www.remove.bg/)（免费额度每月 50 张），同样在设置页配置 API Key。未配置 AI 服务时，睡眠页的本地预测与首页贴士仍可正常使用。

## 项目结构

```
lib/
├── main.dart                入口（Provider 装配）
├── app.dart                 MaterialApp + 主题
├── core/
│   ├── app_info.dart        版本信息（与 pubspec.yaml / assets/changelog.json 同步）
│   ├── constants.dart       AI 服务商预设 / 地域饮食库 / 鞋码表
│   ├── nexio.dart           Nexio 设计令牌（色彩 / 字号 / 圆角 / 动效）
│   ├── text_utils.dart      通用文本工具（twoDigits）
│   └── theme.dart           Material 3 主题
├── models/                  BabyProfile / SleepRecord / MealRecord / FeedingRecord /
│                            GrowthRecord / PredictionResult / PhotoMemory / Changelog / DietAdvice
├── services/
│   ├── database_service.dart          sqflite（v4：睡眠 / 饮食 / 喂养 / 成长 / 照片 / 预测缓存）
│   ├── settings_store.dart            shared_preferences 配置
│   ├── ai_service.dart                OpenAI 兼容 chat completions（dio）
│   ├── background_removal_service.dart remove.bg 客户端
│   ├── joint_sleep_predictor.dart      饮食×睡眠联合建模预测器
│   ├── food_features.dart              食物类型 → 饮食特征映射
│   ├── diet_safety_validator.dart      喂养安全校验
│   ├── shoe_size_matcher.dart          鞋码换算
│   ├── parenting_tips.dart             月龄育儿贴士
│   ├── data_export_service.dart        本地数据导出
│   ├── changelog_service.dart          更新日志读取
│   └── update_service.dart             GitHub Release / Tag 版本检查
├── providers/                Baby / Sleep / Diet / Feeding / Growth / Gallery / Settings 七个状态层
├── widgets/
│   ├── nexio_glass.dart      玻璃构件（GlassCard / NexioChoiceChip / NexioNoteCard / NexioStat …）
│   ├── nexio_pickers.dart    滚轮日期 / 时间选择器与锚定下拉浮层
│   └── common_widgets.dart   通用组件
└── pages/                    main_shell（底部导航）+ home / sleep / diet / feeding / growth /
                              tools / shoes / gallery / settings / changelog

test/                         单元测试（diet_safety / joint_sleep / update_check / shoe_size /
                              changelog / tools_models）
tool/                         本地审计脚本（storage_audit.py / apk_audit.py）
```

## 运行

```bash
flutter pub get
flutter run
flutter test        # 跑单元测试
```

> Android 端要求：Flutter 3.47+，AGP 9.1，Gradle 9.3.1，JDK 17（`flutter doctor` 检查环境）。
> 发布构建采用 ABI 拆分，单设备安装包约 18.5MB。

## 说明

- AI 预测仅供参考，不能替代专业医疗建议；宝宝出现持续异常哭闹、睡眠严重紊乱请及时就医。
- 所有记录仅存本地（sqflite / shared_preferences）；只有「AI 分析 / 去背景 / 检查更新」会按需访问对应服务，不上传其他内容。
