import 'package:PiliPlus/models/dynamics/result.dart';

/// 动态里挂载了可播放稿件的类型：投稿、合集、番剧、课程。
/// 其余（图文、转发、直播、专栏…）在精简模式下不展示。
const _videoTypes = {
  'DYNAMIC_TYPE_AV',
  'DYNAMIC_TYPE_UGC_SEASON',
  'DYNAMIC_TYPE_PGC_UNION',
  'DYNAMIC_TYPE_COURSES_SEASON',
};

extension DynamicItemExt on DynamicItemModel {
  /// 动态携带的稿件信息，纯图文或转发为 null。
  DynamicArchiveModel? get videoArchive {
    final major = modules.moduleDynamic?.major;
    return switch (type) {
      'DYNAMIC_TYPE_AV' => major?.archive,
      'DYNAMIC_TYPE_UGC_SEASON' => major?.ugcSeason,
      'DYNAMIC_TYPE_PGC_UNION' => major?.pgc,
      'DYNAMIC_TYPE_COURSES_SEASON' => major?.courses,
      _ => null,
    };
  }

  bool get isVideoDynamic => _videoTypes.contains(type) && videoArchive != null;

  /// 能当普通稿件处理的 bvid。番剧、课程那一支给的是 epid，拿去查稿件接口会失败。
  String? get videoBvid {
    final bvid = videoArchive?.bvid;
    return bvid != null && bvid.startsWith('BV') ? bvid : null;
  }

  /// 充电专属投稿：稿件卡片右上角的「充电专属」徽标。
  bool get isChargingVideo {
    final text = videoArchive?.badge?.text;
    return text != null && text.contains('充电');
  }
}
