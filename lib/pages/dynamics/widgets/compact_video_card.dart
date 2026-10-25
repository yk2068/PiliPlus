import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/utils/extension/dynamic_ext.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

/// 动态页精简模式下的视频卡片：只有封面、时长和标题，点开就是视频。
/// [horizontal] 为 true 时封面在左、信息在右，卡片只有封面那么高。
class CompactVideoCard extends StatelessWidget {
  const CompactVideoCard({
    super.key,
    required this.item,
    required this.horizontal,
  });

  final DynamicItemModel item;
  final bool horizontal;

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final video = item.videoArchive;
    if (video == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => PageUtils.pushDynDetail(item),
      child: horizontal
          ? LayoutBuilder(
              builder: (context, constraints) {
                final coverWidth = constraints.maxWidth * 0.4;
                final coverHeight = coverWidth / Style.aspectRatio;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _title(video, 13),
                            _meta(theme, video, 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: Style.aspectRatio,
                  child: _cover(video),
                ),
                const SizedBox(height: 5),
                _title(video, 12),
              ],
            ),
    );
  }

  Widget _title(DynamicArchiveModel video, double fontSize) => Text(
    video.title ?? '',
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: fontSize,
      height: 1.25,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _meta(ThemeData theme, DynamicArchiveModel video, double fontSize) {
    final upName = item.modules.moduleAuthor?.name;
    final play = video.stat?.play;
    final text = [
      ?upName,
      if (play != null) '${NumUtils.numFormat(play)}播放',
    ].join(' · ');
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        color: theme.colorScheme.outline,
      ),
    );
  }

  Widget _cover(DynamicArchiveModel video) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        NetworkImgLayer(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          src: video.cover,
          quality: 40,
          borderRadius: _radius,
        ),
        if (video.durationText case final durationText?)
          Positioned(
            right: 4,
            bottom: 4,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  durationText,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
