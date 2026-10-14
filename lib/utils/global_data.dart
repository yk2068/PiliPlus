import 'package:PiliPlus/utils/storage_pref.dart';

class GlobalData {
  int imgQuality = Pref.picQuality;

  num? coins;

  void afterCoin(num coin) {
    if (coins != null) {
      coins = coins! - coin;
    }
  }

  Set<int> blackMids = Pref.blackMids;

  /// 点踩过的视频（bvid），全场景屏蔽
  Set<String> dislikedBvids = Pref.dislikedBvids;


  bool dynamicsWaterfallFlow = Pref.dynamicsWaterfallFlow;

  bool showMedal = Pref.showMedal;

  // 私有构造函数
  GlobalData._();

  // 单例实例
  static final GlobalData _instance = GlobalData._();

  // 获取全局实例
  factory GlobalData() => _instance;
}

extension IterableExt<E> on Iterable<E> {
  Iterable<E> whereNotBlocked(Object? /* mid */ Function(E element) test) =>
      where((e) => !GlobalData().blackMids.contains(test(e)));
}
