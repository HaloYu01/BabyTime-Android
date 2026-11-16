# 代码与注释精简变更清单

- 备份目录：`_backup_pre_slim/20261116_202141`
- 精简前 lib 总行数：8335
- 精简后 lib 总行数：8293
- 净减少：42 行

## 具体改动

### 1. 未使用依赖与令牌
- 删除 pubspec 未使用依赖 `fl_chart`（lib 内零引用）。
- 删除未使用令牌：`NexioColors.onPrimaryVariant/glassFill/glassFillStrong/glassBorder/glassShadow/barFill/windowDimming`。
- 删除未使用动效：`NexioMotion.quintOut/secondaryPageOut/fastOutSlowIn/material`。

### 2. 重复代码合并
- 新增 `NexioChoiceChip`，替换 6 处重复 ChoiceChip 样式（feeding/growth/shoe/sleep_edit/meal_sheet×2）。
- 新增 `NexioNoteCard`，替换 3 处重复「浅灰提示卡」结构。
- 删除冗余包装 `_SizeStat`，改用 `NexioStat`。
- 新增 `core/text_utils.dart#twoDigits`，替换 2 处私有 `_two` 实现。

### 3. 注释精简
- 更新过时注释：`Nexio 液态玻璃设计令牌` → `Nexio 设计令牌`；`圆形玻璃按钮` → `圆形模糊按钮`；删除「玻璃构件专用」旧分组说明。

## 文件行数变化（主要）

| 文件 | 精简前 | 精简后 | 变化 |
|---|---|---|---|
| pages\feeding\feeding_page.dart | 270 | 250 | -20 |
| pages\shoes\shoe_helper_page.dart | 363 | 344 | -19 |
| pages\diet\widgets\meal_record_edit_sheet.dart | 232 | 219 | -13 |
| pages\tools\data_export_page.dart | 158 | 146 | -12 |
| core\nexio.dart | 105 | 94 | -11 |
| pages\tools\tools_page.dart | 184 | 173 | -11 |
| pages\growth\growth_page.dart | 421 | 413 | -8 |
| pages\sleep\sleep_record_edit_page.dart | 231 | 224 | -7 |
| pages\settings\changelog_page.dart | 235 | 234 | -1 |
| core\text_utils.dart | 0 | 2 | +2 |
| widgets\nexio_glass.dart | 604 | 662 | +58 |
