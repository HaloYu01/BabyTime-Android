class MealRecord {
  final int? id;
  final DateTime time;

  /// 食物类型：由家长自由填写（不限于预置标签）。
  final String foodType;

  /// 旧版「其他」类型的具体名称（仅兼容历史数据）。
  final String? customFoodName;

  /// 进食份量（偏少/正常/偏多，可选）。
  final String? portion;

  /// 餐后反应（无异常/胀气/吐奶/疑似过敏/便秘，可选）。
  final String? afterEffect;
  final String description;

  const MealRecord({
    this.id,
    required this.time,
    required this.foodType,
    this.customFoodName,
    this.portion,
    this.afterEffect,
    this.description = '',
  });

  /// 列表展示：兼容旧「其他 · 山药泥」。
  String get foodLabel {
    final name = customFoodName?.trim() ?? '';
    if (foodType == '其他' && name.isNotEmpty) {
      return '其他 · $name';
    }
    return foodType;
  }

  /// AI 提示词展示：兼容旧「其他（山药泥）」。
  String get promptLabel {
    final name = customFoodName?.trim() ?? '';
    if (foodType == '其他' && name.isNotEmpty) {
      return '其他（$name）';
    }
    return foodType;
  }

  /// 联合建模使用的有效食物名称（自由类型优先）。
  String get effectiveFoodName {
    final type = foodType.trim();
    if (type == '其他') {
      final name = customFoodName?.trim() ?? '';
      return name.isEmpty ? '其他' : name;
    }
    return type.isEmpty ? '未记录' : type;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'time': time.toIso8601String(),
        'food_type': foodType,
        'custom_food_name': customFoodName,
        'portion': portion,
        'after_effect': afterEffect,
        'description': description,
      };

  static MealRecord fromMap(Map<String, dynamic> map) => MealRecord(
        id: map['id'] as int?,
        time: DateTime.tryParse(map['time'] as String? ?? '') ?? DateTime.now(),
        foodType: map['food_type'] as String? ?? '其他',
        customFoodName: map['custom_food_name'] as String?,
        portion: map['portion'] as String?,
        afterEffect: map['after_effect'] as String?,
        description: map['description'] as String? ?? '',
      );
}