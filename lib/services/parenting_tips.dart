/// 每日育儿贴士：按宝宝月龄阶段提供本地规则内容（无需联网/AI）。
class ParentingTip {
  final String title;
  final String body;
  const ParentingTip(this.title, this.body);
}

class ParentingTips {
  /// 按日期轮换，保证每天有新鲜内容且当天内稳定。
  static ParentingTip forToday({required int months}) {
    final tips = _byStage(months);
    final day = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    return tips[day % tips.length];
  }

  static List<ParentingTip> _byStage(int months) {
    if (months < 6) {
      return const [
        ParentingTip('奶睡不是坏习惯', '0~6 个月按需喂养即可。睡前喂饱、拍嗝后放床，能减少夜间胀气性醒来。'),
        ParentingTip('区分白天与黑夜', '白天拉开窗帘、保留正常生活噪音；夜间喂奶保持昏暗安静，帮助建立昼夜节律。'),
        ParentingTip('夜醒很常见', '这个月龄每晚醒 2~3 次是正常的。先观察 1~2 分钟再回应，给宝宝自我安抚的机会。'),
        ParentingTip('从记录第一晚开始', '连续记录 3 天入睡与夜醒，App 就能开始预测今晚的夜醒时段。'),
      ];
    }
    if (months < 12) {
      return const [
        ParentingTip('辅食质地要匹配', '8 个月左右可从泥糊过渡到软烂碎末，小块状食物能锻炼咀嚼，也有助于夜间睡得更沉。'),
        ParentingTip('晚餐与睡前留间隔', '最后一餐尽量安排在睡前 2~3 小时，减少胀气与夜间消化负担。'),
        ParentingTip('白天多趴多爬', '充足的活动与爬行练习能提升夜间“睡眠压力”，入睡更快、夜醒更少。'),
        ParentingTip('新食材一次一种', '引入新辅食时每次只加一种，观察 2~3 天，便于定位夜间不适的原因。'),
      ];
    }
    if (months < 24) {
      return const [
        ParentingTip('固定睡前仪式', '洗澡—换睡衣—读绘本的固定顺序，能让宝宝提前进入睡眠状态。'),
        ParentingTip('警惕睡前过饱', '晚餐过饱或临睡前喝大量奶，容易造成夜间翻来覆去。'),
        ParentingTip('逐步过渡到一次午睡', '这个阶段可尝试一次午睡，避免傍晚补觉影响夜间入睡。'),
        ParentingTip('出牙期夜醒增多', '出牙、疫苗后夜醒增多通常是暂时的，记录健康事件能让预测更准。'),
      ];
    }
    return const [
      ParentingTip('作息稳定最重要', '固定入睡与起床时间，比单纯追求“睡够时长”更能改善睡眠质量。'),
      ParentingTip('晚餐清淡少糖', '高糖零食会让血糖波动、增加夜间觉醒，晚餐以清淡家常为主。'),
      ParentingTip('睡前 1 小时降刺激', '睡前避免剧烈玩耍和屏幕，改为安静游戏或绘本。'),
      ParentingTip('关注白天情绪', '分离焦虑或情绪波动也会影响夜间睡眠，白天多陪伴能减少夜醒。'),
    ];
  }
}