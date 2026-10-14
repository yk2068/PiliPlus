import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/video/ai_conclusion/view.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class _VideoCustomAction {
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _VideoCustomAction(this.title, this.icon, this.onTap);
}

class VideoPopupMenu extends StatelessWidget {
  final double? iconSize;
  final double menuItemHeight;
  final BaseSimpleVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoPopupMenu({
    super.key,
    required this.iconSize,
    required this.videoItem,
    this.onRemove,
    this.menuItemHeight = 45,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert_outlined,
        color: Theme.of(context).colorScheme.outline,
        size: iconSize,
      ),
      position: PopupMenuPosition.under,
      itemBuilder: (context) =>
          [
                if (videoItem.bvid?.isNotEmpty == true) ...[
                  _VideoCustomAction(
                    videoItem.bvid!,
                    const Icon(CustomIcons.identifier_circle, size: 16),
                    () => Utils.copyText(videoItem.bvid!),
                  ),
                  if (Accounts.main.isLogin)
                    _VideoCustomAction(
                      '稍后再看',
                      const Icon(MdiIcons.clockTimeEightOutline, size: 16),
                      () => UserHttp.toViewLater(bvid: videoItem.bvid),
                    ),
                  if (videoItem.cid != null && Pref.enableAi)
                    _VideoCustomAction(
                      'AI总结',
                      const Icon(CustomIcons.ai_circle, size: 16),
                      () async {
                        final res = await UgcIntroController.getAiConclusion(
                          videoItem.bvid!,
                          videoItem.cid!,
                          videoItem.owner.mid,
                        );
                        if (res != null && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Padding(
                                padding: const .symmetric(vertical: 14),
                                child: AiConclusionPanel.buildContent(
                                  context,
                                  Theme.of(context),
                                  res,
                                  tap: false,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
                if (videoItem is! SpaceArchiveItem) ...[
                  _VideoCustomAction(
                    '访问：${videoItem.owner.name}',
                    const Icon(MdiIcons.accountCircleOutline, size: 16),
                    () => Get.toNamed('/member?mid=${videoItem.owner.mid}'),
                  ),
                  _VideoCustomAction(
                    Pref.isDislikedBvid(videoItem.bvid) ? '撤销点踩' : '不感兴趣',
                    const Icon(MdiIcons.thumbDownOutline, size: 16),
                    () => _dislike(videoItem, onRemove),
                  ),
                  _VideoCustomAction(
                    '拉黑：${videoItem.owner.name}',
                    const Icon(MdiIcons.cancel, size: 16),
                    () => showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('提示'),
                          content: Text(
                            '确定拉黑:${videoItem.owner.name}(${videoItem.owner.mid})?'
                            '\n\n注：被拉黑的Up可以在隐私设置-黑名单管理中解除',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Get.back();
                                Pref.setBlackMid(videoItem.owner.mid!);
                                onRemove?.call();
                              },
                              child: const Text('本地屏蔽'),
                            ),
                            TextButton(
                              onPressed: Get.back,
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: ColorScheme.of(context).outline,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Get.back();
                                final res = await VideoHttp.relationMod(
                                  mid: videoItem.owner.mid!,
                                  act: 5,
                                  reSrc: 11,
                                );
                                if (res.isSuccess) {
                                  onRemove?.call();
                                } else {
                                  res.toast();
                                }
                              },
                              child: const Text('确认'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                _VideoCustomAction(
                  "${MineController.anonymity.value ? '退出' : '进入'}无痕模式",
                  MineController.anonymity.value
                      ? const Icon(MdiIcons.incognitoOff, size: 16)
                      : const Icon(MdiIcons.incognito, size: 16),
                  MineController.onChangeAnonymity,
                ),
              ]
              .map(
                (e) => PopupMenuItem(
                  height: menuItemHeight,
                  onTap: e.onTap,
                  child: Row(
                    children: [
                      e.icon,
                      const SizedBox(width: 6),
                      Text(e.title, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

/// 点踩/撤销点踩：一步到位，不再弹二次确认框
///
/// 点踩成功后会把 bvid 记到本地名单，全场景（推荐/热门/排行/相关）都不再出现；
/// 再次点击同一条即视为撤销。
Future<void> _dislike(
  BaseSimpleVideoItemModel videoItem,
  VoidCallback? onRemove,
) async {
  final rcmd = Accounts.get(.recommend);
  if (rcmd.accessKey == null || rcmd.accessKey == '') {
    SmartDialog.showToast(rcmd.isLogin ? '请退出账号后重新登录' : '账号未登录');
    return;
  }

  final bvid = videoItem.bvid;
  if (bvid == null || bvid.isEmpty) {
    SmartDialog.showToast('未能获取 bvid');
    return;
  }

  final bool isAppRcmd = videoItem is RcmdVideoItemAppModel;
  final bool alreadyDisliked = Pref.isDislikedBvid(bvid);

  if (alreadyDisliked) {
    SmartDialog.showLoading(msg: '正在撤销');
    final bool ok = isAppRcmd
        ? (await VideoHttp.feedDislikeCancel(
            id: (videoItem as RcmdVideoItemAppModel).param!,
            goto: videoItem.goto!,
          )).isSuccess
        : (await VideoHttp.dislikeVideo(bvid: bvid, type: false)).isSuccess;
    SmartDialog.dismiss();
    if (ok) {
      Pref.removeDislikedBvid(bvid);
      SmartDialog.showToast('已撤销点踩');
    } else {
      SmartDialog.showToast('撤销失败');
    }
    return;
  }

  SmartDialog.showLoading(msg: '正在提交');
  if (isAppRcmd) {
    final item = videoItem as RcmdVideoItemAppModel;
    final tp = item.threePoint;
    if (tp == null) {
      SmartDialog.dismiss();
      SmartDialog.showToast('未能获取 threePoint');
      return;
    }
    final reason = tp.dislikeReasons?.firstOrNull;
    if (reason == null) {
      SmartDialog.dismiss();
      SmartDialog.showToast('未能获取 dislikeReasons');
      return;
    }
    final res = await VideoHttp.feedDislike(
      reasonId: reason.id,
      id: item.param!,
      goto: item.goto!,
    );
    SmartDialog.dismiss();
    if (!res.isSuccess) {
      res.toast();
      return;
    }
    SmartDialog.showToast(reason.toast ?? '已点踩');
  } else {
    final res = await VideoHttp.dislikeVideo(bvid: bvid, type: true);
    SmartDialog.dismiss();
    if (!res.isSuccess) {
      res.toast();
      return;
    }
    SmartDialog.showToast('已点踩');
  }

  Pref.addDislikedBvid(bvid);
  onRemove?.call();
}
