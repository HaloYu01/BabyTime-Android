/// 从家长自由填写的食物类型中提取结构化饮食特征（联合建模用）。
///
/// 由于食物类型不固定（家长自主填写），这里用关键词映射而不是固定枚举，
/// 未识别的类型不会误判，仅保持全部为 false（由上层作为"未归类"处理）。
class FoodFeatures {
  final bool isWheat; // 小麦/面食
  final bool isRice; // 米类主食
  final bool isDairy; // 奶制品
  final bool isFruit;
  final bool isVeg;
  final bool isProtein; // 肉/蛋/鱼/豆制品
  final bool isSugary; // 甜食/含糖
  final bool isGassy; // 易胀气（豆类/十字花科/高淀粉）
  final bool isAllergen; // 常见致敏（蛋/海鲜/坚果/芒果等）
  final bool isLiquid; // 液体为主（奶/汤/粥/果汁）
  final bool isCaffeine;
  final bool isSpicy;

  const FoodFeatures({
    this.isWheat = false,
    this.isRice = false,
    this.isDairy = false,
    this.isFruit = false,
    this.isVeg = false,
    this.isProtein = false,
    this.isSugary = false,
    this.isGassy = false,
    this.isAllergen = false,
    this.isLiquid = false,
    this.isCaffeine = false,
    this.isSpicy = false,
  });

  bool get isEmpty =>
      !(isWheat ||
          isRice ||
          isDairy ||
          isFruit ||
          isVeg ||
          isProtein ||
          isSugary ||
          isGassy ||
          isAllergen ||
          isLiquid ||
          isCaffeine ||
          isSpicy);

  List<String> get labels {
    final result = <String>[];
    if (isWheat) result.add('面食');
    if (isRice) result.add('米类');
    if (isDairy) result.add('奶制品');
    if (isFruit) result.add('水果');
    if (isVeg) result.add('蔬菜');
    if (isProtein) result.add('蛋白类');
    if (isSugary) result.add('含糖');
    if (isGassy) result.add('易胀气');
    if (isAllergen) result.add('易致敏');
    if (isLiquid) result.add('液体');
    if (isCaffeine) result.add('含咖啡因');
    if (isSpicy) result.add('辛辣');
    return result;
  }
}

class FoodTypeFeatureMapper {
  static const _wheat = [
    '面',
    '馒头',
    '包子',
    '饼',
    '面包',
    '饺',
    '馄饨',
    '意面',
    '小麦',
    '馍',
    '馕',
  ];
  static const _rice = ['米饭', '米', '米粉', '米糊', '粥', '饭'];
  static const _dairy = ['奶', '酸奶', '奶酪', '芝士', '奶粉'];
  static const _fruit = [
    '果',
    '苹果',
    '香蕉',
    '梨',
    '桃',
    '葡萄',
    '橙',
    '莓',
    '西瓜',
    '牛油果',
    '猕猴桃',
    '蓝莓',
    '樱桃',
    '哈密瓜',
  ];
  static const _veg = [
    '菜',
    '蔬',
    '菠菜',
    '西兰花',
    '胡萝卜',
    '南瓜',
    '土豆',
    '番茄',
    '西红柿',
    '青豆',
    '黄瓜',
    '蘑菇',
    '山药',
    '红薯',
  ];
  static const _protein = ['肉', '鸡', '牛', '猪', '鱼', '虾', '蛋', '豆腐', '鳕鱼', '三文鱼'];
  static const _sugary = [
    '糖',
    '甜',
    '蛋糕',
    '饼干',
    '果汁',
    '饮料',
    '巧克力',
    '布丁',
    '冰淇淋',
    '冰激凌',
    '果冻',
    '糖果',
    '蜂蜜',
  ];
  static const _gassy = ['豆', '西兰花', '卷心菜', '洋葱', '红薯', '土豆', '玉米', '花菜', '碳酸'];
  static const _allergen = ['蛋', '虾', '蟹', '鱼', '花生', '坚果', '芒果', '贝', '芝麻'];
  static const _liquid = ['奶', '汤', '粥', '果汁', '水', '米糊'];
  static const _caffeine = ['茶', '咖啡', '可乐'];
  static const _spicy = ['辣', '麻'];

  static bool _has(String text, List<String> keys) =>
      keys.any(text.contains);

  static FoodFeatures map(String rawType) {
    final text = rawType.trim();
    if (text.isEmpty) return const FoodFeatures();
    return FoodFeatures(
      isWheat: _has(text, _wheat),
      isRice: _has(text, _rice),
      isDairy: _has(text, _dairy),
      isFruit: _has(text, _fruit),
      isVeg: _has(text, _veg),
      isProtein: _has(text, _protein),
      isSugary: _has(text, _sugary),
      isGassy: _has(text, _gassy),
      isAllergen: _has(text, _allergen),
      isLiquid: _has(text, _liquid),
      isCaffeine: _has(text, _caffeine),
      isSpicy: _has(text, _spicy),
    );
  }
}