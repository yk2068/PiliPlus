import 'dart:math';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/horizontal_video_model.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_video.dart' show BaseStat;
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/extension/dynamic_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// 动态页精简模式下的视频卡片，信息与操作照推荐页的卡片来：
/// 封面（时长/充电专属徽标）、标题、UP主与发布时间、播放与弹幕数，
/// 右下角三点菜单（复制bvid、稍后再看、访问UP、不感兴趣、拉黑…）。
/// [horizontal] 为 true 时封面在左、信息在右，整行只有封面那么高。
class CompactVideoCard extends StatelessWidget {
  const CompactVideoCard({
    super.key,
    required this.item,
    required this.horizontal,
  });

  final DynamicItemModel item;
  final bool horizontal;

  static const _radius = BorderRadius.all(Radius.circular(8));
  static final _shortDate = DateFormat('M-d');
  static final _longDate = DateFormat('yy-M-d');

  @override
  Widget build(BuildContext context) {
    final video = item.videoArchive;
    if (video == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    void onLongPress() => imageSaveDialog(
      title: video.title,
      cover: video.cover,
      bvid: item.videoBvid,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => PageUtils.pushDynDetail(item),
          onLongPress: onLongPress,
          onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
          child: horizontal
              ? _horizontal(theme, video)
              : _vertical(theme, video),
        ),
        // 番剧、课程拿不到稿件 bvid，菜单里的操作大多用不了，索性不显示
        if (item.videoBvid != null)
          Positioned(
            right: -6,
            bottom: -4,
            width: 26,
            height: 26,
            child: VideoPopupMenu(
              iconSize: 16,
              videoItem: _DynVideoItem(item),
            ),
          ),
      ],
    );
  }

  Widget _horizontal(ThemeData theme, DynamicArchiveModel video) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverHeight = constraints.maxHeight;
        final coverWidth = min(
          coverHeight * Style.aspectRatio,
          constraints.maxWidth * 0.45,
        );
        return Row(
          children: [
            SizedBox(
              width: coverWidth,
              height: coverHeight,
              child: _cover(video),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: coverHeight,
                child: _info(
                  theme,
                  video,
                  spacing: MainAxisAlignment.spaceBetween,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _vertical(ThemeData theme, DynamicArchiveModel video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: Style.aspectRatio, child: _cover(video)),
        const SizedBox(height: 5),
        _info(theme, video, spacing: MainAxisAlignment.start),
      ],
    );
  }

  Widget _info(
    ThemeData theme,
    DynamicArchiveModel video, {
    required MainAxisAlignment spacing,
  }) {
    final author = item.modules.moduleAuthor;
    final pubdate = DateFormatUtils.dateFormat(
      author?.pubTs,
      short: _shortDate,
      long: _longDate,
    );
    final subtitle = [
      ?author?.name,
      if (pubdate.isNotEmpty) pubdate,
    ].join(' · ');
    final play = video.stat?.play;
    final danmu = video.stat?.danmu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: spacing,
      children: [
        Flexible(
          child: Text(
            video.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        if (play != null || danmu != null)
          Padding(
            // 右侧让开三点菜单
            padding: const EdgeInsets.only(top: 3, right: 18),
            child: Row(
              spacing: 8,
              children: [
                if (play != null) StatWidget(type: StatType.play, value: play),
                if (danmu != null)
                  StatWidget(type: StatType.danmaku, value: danmu),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cover(DynamicArchiveModel video) => LayoutBuilder(
    builder: (context, constraints) {
      final badge = video.badge?.text;
      return Stack(
        children: [
          NetworkImgLayer(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            src: video.cover,
            quality: 40,
            borderRadius: _radius,
          ),
          if (badge != null)
            PBadge(
              text: badge,
              top: 6,
              right: 6,
              size: PBadgeSize.small,
              type: badge.contains('充电')
                  ? PBadgeType.error
                  : PBadgeType.primary,
            ),
          if (video.durationText case final durationText?)
            PBadge(
              text: durationText,
              right: 6,
              bottom: 6,
              size: PBadgeSize.small,
              type: PBadgeType.gray,
            ),
        ],
      );
    },
  );
}

/// 动态条目转成推荐页那套卡片组件认识的视频模型，好直接复用三点菜单。
class _DynVideoItem extends HorizontalVideoModel {
  _DynVideoItem(DynamicItemModel item) {
    final video = item.videoArchive!;
    final author = item.modules.moduleAuthor;
    title = video.title ?? '';
    cover = video.cover;
    bvid = item.videoBvid;
    badge = video.badge?.text;
    pubdate = author?.pubTs;
    owner = Owner(mid: author?.mid, name: author?.name);
    stat = _DynStat(video.stat);
  }
}

class _DynStat extends BaseStat {
  _DynStat(Stat? stat) {
    view = _parse(stat?.play);
    danmu = _parse(stat?.danmu);
  }

  /// 动态接口给的是「1.2万」这种现成文案，取不到整数就算了
  static int? _parse(String? value) =>
      value == null ? null : int.tryParse(value);
}
