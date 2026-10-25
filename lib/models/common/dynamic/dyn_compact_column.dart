import 'package:PiliPlus/models/common/enum_with_label.dart';

/// 动态页精简模式下每行放几个视频卡片
enum DynCompactColumn implements EnumWithLabel {
  one('一行一个', 1),
  two('一行两个', 2),
  ;

  @override
  final String label;

  /// 每行的卡片数量
  final int count;

  const DynCompactColumn(this.label, this.count);

  static DynCompactColumn fromIndex(int? index) =>
      index != null && index >= 0 && index < values.length
      ? values[index]
      : two;
}
