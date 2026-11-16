# BabyTime 育儿助手

一款面向新手父母的育儿辅助 App（Flutter / Android）。

## 功能

### 1. AI 睡眠预测（核心）
记录宝宝每次的入睡时间、最终醒来时间、夜醒次数和哭闹情况，AI 会根据最近 7 天的作息数据：
- 预测今晚最可能的**夜醒时间点**（附概率与原因）
- 预测**哭闹高风险时段**
- 给出可执行的**改善建议**

### 2. 地域饮食建议
结合宝宝所在地区的饮食差异（内置 28 个省市的饮食特征库，如面食/米饭、口味浓淡、夜宵文化等）与最近的饮食、睡眠记录，AI 生成：
- 今日各餐的具体建议
- 饮食对今晚睡眠质量的影响分析

### 3. 宝宝选鞋助手
- 脚长测量指导 + 滑块输入
- 成长放量选择（学步鞋 0.5~1cm）→ 推荐鞋内长
- 中国码 / EU / US 尺码对照表（10.5~20cm 全覆盖）
- 「一折二捏三挤四闻五试」选购要点
- AI 选购答疑（如「宝宝扁平足适合什么鞋」）

### 4. 照片成长记录
- 拍照 / 相册导入
- 一键 **AI 去背景**（remove.bg），只留主体
- 按日期归档，抠图/原图切换查看

## AI 服务配置（设置页）

所有 AI 能力走 **OpenAI 兼容格式**，无需改代码即可切换：

| 服务商 | 默认模型 | 说明 |
|---|---|---|
| 智谱 GLM | glm-4-flash | 有免费模型，推荐起步 |
| DeepSeek | deepseek-chat | 便宜好用 |
| 通义千问 | qwen-plus | 阿里云 |
| Kimi | moonshot-v1-8k | 长文本 |
| 自定义 | - | 任意 OpenAI 兼容接口 |

到对应平台申请 API Key，在 App 内「工具 → 设置」填入即可（仅本地存储）。

去背景功能使用 [remove.bg](https://www.remove.bg/)（免费额度每月 50 张），同样在设置页配置 API Key。

## 项目结构

```
lib/
├── main.dart              入口（Provider 装配）
├── app.dart               MaterialApp + 主题
├── core/
│   ├── theme.dart         Material 3 主题
│   └── constants.dart     AI 服务商预设 / 地域饮食库 / 鞋码表
├── models/                BabyProfile / SleepRecord / MealRecord / PredictionResult / PhotoMemory
├── services/
│   ├── database_service.dart   sqflite（睡眠/饮食/照片/预测缓存四张表）
│   ├── settings_store.dart     shared_preferences 配置
│   ├── ai_service.dart         OpenAI 兼容 chat completions（dio）
│   └── background_removal_service.dart  remove.bg 客户端
├── providers/             Sleep / Diet / Gallery / Baby / Settings 五个状态层
└── pages/                 main_shell（底部导航）+ home / sleep / diet / tools / shoes / gallery / settings
```

## 运行

```bash
flutter pub get
flutter run
```

> Android 端要求：Flutter 3.47+，AGP 9.1，Gradle 9.3.1，JDK 17（`flutter doctor` 检查环境）。

## 说明

- AI 预测仅供参考，不能替代专业医疗建议；宝宝出现持续异常哭闹、睡眠严重紊乱请及时就医。
- 所有数据仅存本地（sqflite / shared_preferences），不上传服务器。