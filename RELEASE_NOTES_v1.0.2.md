# BabyTime v1.0.2

> 面向新手父母的育儿辅助 App（Flutter / Android）——记录睡眠与饮食，给出今晚睡眠预测、地域饮食建议与选鞋参考，数据全部存在手机本地。

- **版本**：1.0.2（versionCode 3）
- **包名**：`com.babytime.babytime`
- **系统要求**：Android 7.0+（minSdk 24），targetSdk 36
- **发布类型**：Android 安装包（未上架应用商店）

## 本版重点

- **工具页成型**：新增「成长记录」（身高 / 体重 / 头围 + 生长曲线）、「喂养计时器」（母乳左/右侧、瓶喂，自动保存记录）、「数据备份与导出」（一键导出 JSON，不上传服务器）；工具页按「宝宝成长 / 记录与照顾 / 选购与影像 / 数据与安全」分组重排，信息密度提升。
- **导出文件可在手机文件夹中找到**：改用系统保存对话框（SAF），保存时可直接选择「下载 / 文档」目录，保存后可在文件管理器中查看；取消保存不报错，可再次保存或复制 JSON。
- **数据兼容**：数据库 v3 → v4 自动迁移（新增成长 / 喂养表），旧记录不丢失。
- **安装包进一步瘦身**：release 开启 R8 代码缩减与资源收缩，应用图标改为 WebP；配合 ABI 拆分，通用包 53.2 MB → 单设备约 18 MB（约 -65%，v7a ≈16 MB、x86_64 ≈19.5 MB）。

## 下载与安装（ABI 拆分，推荐）

本版起推荐按 ABI 拆分构建，单设备安装体积大幅下降（原通用包约 53 MB）：

| 文件 | 预估大小 | 说明 |
|---|---|---|
| `app-arm64-v8a-release.apk` | 约 18.5 MB | 现代真机（绝大多数用户） |
| `app-armeabi-v7a-release.apk` | 约 16 MB | 老设备 |
| `app-x86_64-release.apk` | 约 19.5 MB | 模拟器 / x86 设备 |

构建命令：

```bash
flutter build apk --release --split-per-abi
```

或直接使用脚本（自动构建并列出各包体积）：

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_release.ps1
```

> SHA-256 与精确体积以本地构建产物为准，发布时补充到本文件与 GitHub Release。

安装步骤：下载对应 ABI 的 APK → 允许「安装未知来源应用」→ 打开安装。首次启动无需联网，AI 能力需自行在设置页配置。

## 完整变更

见仓库内 [CHANGELOG.md](https://github.com/HaloYu01/BabyTime-Android/blob/main/CHANGELOG.md) 的 `[1.0.2]` 区块。

## 已知限制

- **签名**：本包使用 Flutter 默认 debug 密钥签名（`android/app/build.gradle.kts` 中 `signingConfig = signingConfigs.getByName("debug")`）。可正常安装，但换成正式 release 密钥后覆盖安装会失败，需先卸载。
- 未上架应用商店，仅本项目 Release 提供 APK。
- AI 预测仅供参考，不能替代专业医疗建议；宝宝持续异常哭闹或睡眠严重紊乱请及时就医。

## AI 服务配置（可选）

不配置也能用：本地睡眠预测、首页贴士、成长记录、喂养计时、数据导出全部离线可用。配置方法：设置页填入任意 OpenAI 兼容接口的 Base URL、模型与 API Key（仅存本机）。

## 隐私

睡眠、饮食、喂养、成长、照片记录全部存在本机（sqflite / shared_preferences），不做云端同步；只有「AI 分析」「去背景」「检查更新」会按需访问对应服务。