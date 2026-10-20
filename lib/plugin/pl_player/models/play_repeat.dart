import 'package:PiliPlus/models/common/enum_with_label.dart';

/// 播放模式。
///
/// 该枚举以 `index` 形式持久化在 `VideoBoxKey.playRepeat` 中，
/// 新值只能追加到末尾，插入中间会让已保存的设置整体错位。
enum PlayRepeat implements EnumWithLabel {
  pause('播完暂停'),
  listOrder('顺序播放'),
  singleCycle('单个循环'),
  listCycle('列表循环'),
  autoPlayRelated('自动连播'),
  partOrder('分P连播'),
  ;

  @override
  final String label;
  const PlayRepeat(this.label);
}
