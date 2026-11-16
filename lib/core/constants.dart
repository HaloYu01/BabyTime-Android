class AiProviderPreset {
  final String id;
  final String name;
  final String baseUrl;
  final String defaultModel;
  const AiProviderPreset(this.id, this.name, this.baseUrl, this.defaultModel);
}

const aiPresets = [
  AiProviderPreset('zhipu', '智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4',
      'glm-4-flash'),
  AiProviderPreset('deepseek', 'DeepSeek', 'https://api.deepseek.com',
      'deepseek-chat'),
  AiProviderPreset(
      'qwen', '通义千问', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-plus'),
  AiProviderPreset('moonshot', 'Kimi', 'https://api.moonshot.cn/v1',
      'moonshot-v1-8k'),
  AiProviderPreset('custom', '自定义', '', ''),
];

/// 常用食物类型快捷标签（仅作输入辅助；类型由家长自由填写，不构成固定枚举）。
const commonFoodTypes = <String>[
  '米饭',
  '面食',
  '粥类',
  '米粉',
  '水果',
  '蔬菜',
  '肉蛋',
  '奶类',
  '零食',
  '汤羹',
];

/// 进食份量（可选记录，用于联合建模）。
const mealPortions = <String>['偏少', '正常', '偏多'];

/// 餐后反应（可选记录，用于联合建模）。
const mealAfterEffects = <String>['无异常', '胀气', '吐奶', '疑似过敏', '便秘'];

/// 白天活动量档位（可选记录，用于联合建模）。
const activityLevels = <String>['很少', '一般', '充足'];

/// 常见省份/地区的饮食特征，作为 AI 提示词的地域背景知识。
const regionDietTraits = {
  '北京': '北方饮食为主，面食与米饭混合，晚餐较晚，口味偏咸香',
  '上海': '江南饮食，偏甜口，米饭为主，辅食讲究精细清淡',
  '广东': '清淡少油，粥品和汤水常见，米饭为主，晚间常有夜宵文化',
  '四川': '麻辣油腻偏重，米饭为主，家庭饮食辛辣度高需注意',
  '重庆': '麻辣重油，米饭为主，夜宵文化浓',
  '湖南': '香辣重口，米饭为主，腌腊食品较多',
  '湖北': '米面兼有，热干面等面食早餐多，口味偏重',
  '河南': '面食为主（烩面、馒头），晚餐常吃面，口味咸香',
  '山东': '面食与煎饼为主，大葱大蒜常见，口味偏咸鲜',
  '陕西': '面食为主（油泼面、肉夹馍），口味酸辣咸香',
  '山西': '面食种类繁多，口味偏咸酸，醋使用普遍',
  '东北': '米饭为主，炖菜量大多油盐，冬天饮食热量高',
  '江浙': '清淡偏甜，米饭为主，水产丰富',
  '福建': '清淡鲜甜，汤粥常见，米饭为主，海鲜多',
  '云南': '米线等米制品为主，菌菇丰富，口味多样',
  '贵州': '酸辣口味，米饭为主，发酵食品多',
  '广西': '米粉为主，口味酸辣清淡兼有',
  '新疆': '面食肉类为主（馕、拉条子），牛羊肉多，口味浓郁',
  '甘肃': '面食牛肉面为主，口味偏咸辣',
  '内蒙古': '奶制品肉类丰富，面食较多，口味偏咸',
  '海南': '清淡海鲜粥品，米饭为主',
  '天津': '面食煎饼果子为主，口味偏咸香',
  '安徽': '米面兼有，口味偏咸辣',
  '江西': '香辣口味，米饭为主',
  '河北': '面食为主，口味偏咸',
  '香港': '清淡粤式饮食，粥粉面饭混合',
  '澳门': '粤式清淡与葡式融合',
  '台湾': '清淡偏甜，米饭面食兼有',
};

class ShoeSizeRow {
  final double footLengthCm;
  final String euSize;
  final String cnSize;
  final String usSize;
  const ShoeSizeRow(this.footLengthCm, this.euSize, this.cnSize, this.usSize);
}

/// 童鞋尺码对照（脚长 cm -> EU / 中国码 / US 码）。
const shoeSizeTable = [
  ShoeSizeRow(10.5, '17', '18', '2.5'),
  ShoeSizeRow(11.0, '18', '19', '3'),
  ShoeSizeRow(11.5, '18.5', '19.5', '4'),
  ShoeSizeRow(12.0, '19', '20', '4.5'),
  ShoeSizeRow(12.5, '19.5', '21', '5'),
  ShoeSizeRow(13.0, '20', '21.5', '5.5'),
  ShoeSizeRow(13.5, '21', '22', '6'),
  ShoeSizeRow(14.0, '21.5', '22.5', '7'),
  ShoeSizeRow(14.5, '22', '23', '7.5'),
  ShoeSizeRow(15.0, '23', '24', '8'),
  ShoeSizeRow(15.5, '23.5', '24.5', '8.5'),
  ShoeSizeRow(16.0, '24', '25', '9'),
  ShoeSizeRow(16.5, '24.5', '25.5', '9.5'),
  ShoeSizeRow(17.0, '25', '26', '10'),
  ShoeSizeRow(17.5, '25.5', '27', '10.5'),
  ShoeSizeRow(18.0, '26', '27.5', '11'),
  ShoeSizeRow(18.5, '26.5', '28', '11.5'),
  ShoeSizeRow(19.0, '27', '29', '12'),
  ShoeSizeRow(19.5, '27.5', '30', '12.5'),
  ShoeSizeRow(20.0, '28', '31', '13'),
];
/// 婴幼儿饮食阶段：用于把真实月龄映射为确定性规则。
class AgeStage {
  final int minMonth;
  final String name;
  final String form;
  final String guidance;
  const AgeStage(this.minMonth, this.name, this.form, this.guidance);
}

const ageStages = [
  AgeStage(0, '奶类期', '纯奶', '以母乳或配方奶为主，暂不添加辅食，不推荐任何固体食物'),
  AgeStage(6, '泥糊期', '泥糊状', '单一食材逐一引入，每次观察 2~3 天；不加盐、糖、蜂蜜；质地为细腻泥糊'),
  AgeStage(8, '颗粒期', '小颗粒/软烂碎末', '可尝试软烂碎末与小颗粒；禁整粒坚果、果冻、整粒葡萄；不加盐糖'),
  AgeStage(12, '软烂期', '软烂家常', '可少量盐（每日 <1.5g）；禁蜂蜜、整粒坚果与生食；食物切小块'),
  AgeStage(24, '常规期', '常规饮食', '接近家常饮食；控糖控盐；禁酒、含咖啡因食物、整粒坚果'),
];

AgeStage stageForMonths(int months) {
  var result = ageStages.first;
  for (final s in ageStages) {
    if (months >= s.minMonth) result = s;
  }
  return result;
}

/// 月龄禁用食物：months < minMonth 时不得出现在建议中。
class ForbiddenFood {
  final String keyword;
  final int minMonth;
  final String reason;
  const ForbiddenFood(this.keyword, this.minMonth, this.reason);
}

const forbiddenFoods = [
  ForbiddenFood('蜂蜜', 12, '1 岁内存在肉毒杆菌中毒风险'),
  ForbiddenFood('加盐', 12, '1 岁内不加盐，减轻肾脏负担'),
  ForbiddenFood('盐', 12, '1 岁内不加盐'),
  ForbiddenFood('糖', 12, '1 岁内不加糖'),
  ForbiddenFood('果汁', 12, '1 岁内不喝果汁，优先整果'),
  ForbiddenFood('牛奶', 12, '1 岁内不用鲜牛奶替代母乳/配方奶'),
  ForbiddenFood('坚果', 12, '坚果需研碎或制成坚果酱'),
  ForbiddenFood('整粒坚果', 36, '3 岁内存在窒息风险'),
  ForbiddenFood('果冻', 36, '3 岁内存在窒息风险'),
  ForbiddenFood('爆米花', 36, '窒息风险'),
  ForbiddenFood('整粒葡萄', 24, '需四瓣切分'),
  ForbiddenFood('圣女果', 24, '需四瓣切分'),
  ForbiddenFood('生鱼片', 60, '生食风险'),
  ForbiddenFood('生蛋', 12, '沙门氏菌风险'),
  ForbiddenFood('腌', 24, '腌制食品高盐'),
  ForbiddenFood('辣', 24, '刺激性调味'),
  ForbiddenFood('咖啡', 24, '含有咖啡因'),
  ForbiddenFood('茶', 24, '含咖啡因/鞣酸'),
  ForbiddenFood('酒', 216, '任何年龄禁止'),
];

/// 当前月龄下不允许出现的关键词列表（用于提示词与 UI）。
List<String> forbiddenKeywordsFor(int months) => forbiddenFoods
    .where((f) => months < f.minMonth)
    .map((f) => f.keyword)
    .toList();