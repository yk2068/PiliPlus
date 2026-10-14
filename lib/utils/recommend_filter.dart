import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

abstract final class RecommendFilter {
  static int minDurationForRcmd = Pref.minDurationForRcmd;
  static int minPlayForRcmd = Pref.minPlayForRcmd;
  static int minLikeRatioForRecommend = Pref.minLikeRatioForRecommend;
  static bool exemptFilterForFollowed = Pref.exemptFilterForFollowed;
  static bool applyFilterToRelatedVideos = Pref.applyFilterToRelatedVideos;
  static RegExp rcmdRegExp = RegExp(
    Pref.banWordForRecommend,
    caseSensitive: false,
  );
  static bool enableFilter = rcmdRegExp.pattern.isNotEmpty;

  // (web/app)rcmd
  static bool filterWithExempt(BaseVideoItemModel videoItem) {
    //由于相关视频中没有已关注标签，只能视为非关注视频
    if (videoItem.isFollowed && exemptFilterForFollowed) {
      return false;
    }
    return filterAll(videoItem);
  }

  /// hot/rank/[filterWithExempt]
  static bool filterLikeRatio(int? like, int? view) {
    if (view != null) {
      return (view > -1 && view < minPlayForRcmd) ||
          (like != null &&
              like > -1 &&
              like * 100 < minLikeRatioForRecommend * view);
    }
    return false;
  }

  /// hot/rank/[filterWithExempt]
  static bool filterTitle(String title) {
    return (enableFilter && rcmdRegExp.hasMatch(title));
  }

  /// [filterAll]
  static bool filterDuration(int duration) {
    return duration > 0 && duration < minDurationForRcmd;
  }

  /// 点踩过的视频：推荐、热门、排行、相关视频都不再出现
  ///
  /// 直接读 GlobalData 内存集合（O(1)），不用静态缓存，避免增删后不同步
  static bool filterDisliked(String? bvid) =>
      bvid != null && GlobalData().dislikedBvids.contains(bvid);


  /// related/[filterWithExempt]
  static bool filterAll(BaseVideoItemModel videoItem) {
    return filterDuration(videoItem.duration) ||
        filterLikeRatio(videoItem.stat.like, videoItem.stat.view) ||
        filterTitle(videoItem.title) ||
        filterDisliked(videoItem.bvid);
  }
}
