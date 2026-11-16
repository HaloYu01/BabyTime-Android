class BabyProfile {
  String name;
  String gender;
  DateTime birthday;
  String feedingType;
  String region;

  BabyProfile({
    this.name = '宝宝',
    this.gender = '男',
    DateTime? birthday,
    this.feedingType = '母乳',
    this.region = '北京',
  }) : birthday = birthday ?? DateTime.now();

  int get monthsOld {
    final now = DateTime.now();
    var months = (now.year - birthday.year) * 12 + now.month - birthday.month;
    if (now.day < birthday.day) months--;
    return months < 0 ? 0 : months;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'birthday': birthday.toIso8601String(),
        'feedingType': feedingType,
        'region': region,
      };

  static BabyProfile fromJson(Map<String, dynamic> json) => BabyProfile(
        name: json['name'] as String? ?? '宝宝',
        gender: json['gender'] as String? ?? '男',
        birthday:
            DateTime.tryParse(json['birthday'] as String? ?? '') ?? DateTime.now(),
        feedingType: json['feedingType'] as String? ?? '母乳',
        region: json['region'] as String? ?? '北京',
      );

  String describe() =>
      '$name，$gender宝宝，$monthsOld个月龄，喂养方式：$feedingType，所在地区：$region';
}