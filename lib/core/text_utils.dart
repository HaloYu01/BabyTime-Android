/// 两位补零（时间/日期展示）。
String twoDigits(int value) => value.toString().padLeft(2, '0');