import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/http/sub_update.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/extension/dynamic_ext.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class DynamicsTabController
    extends CommonListController<DynamicsDataModel, DynamicItemModel>
    with AccountMixin {
  DynamicsTabController({required this.dynamicsType});
  final DynamicsTabType dynamicsType;

  String? offset;

  late final mainController = Get.find<MainController>();
  final dynamicsController = Get.find<DynamicsController>();

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<void> onRefresh() {
    if (dynamicsType == .all) {
      mainController.setDynCount();
    }
    offset = null;
    return super.onRefresh();
  }

  bool _shouldHide(DynamicItemModel item) =>
      (Pref.blockChargingVideo && item.isChargingVideo) ||
      (GlobalData().dynCompact && !item.isVideoDynamic);

  @override
  List<DynamicItemModel>? getDataList(DynamicsDataModel response) {
    offset = response.offset;
    final items = response.items;
    if (items == null) return null;
    if (!GlobalData().dynCompact && !Pref.blockChargingVideo) {
      return items;
    }
    // 只打不可见标记，不从列表里删：删了会让「本页全是充电视频」变成空页，
    // 而空页会把翻页直接判成到底。
    for (final item in items) {
      if (_shouldHide(item)) {
        item.visible = false;
      }
    }
    return items;
  }

  static int _newestFirst(DynamicItemModel a, DynamicItemModel b) =>
      (b.modules.moduleAuthor?.pubTs ?? 0).compareTo(
        a.modules.moduleAuthor?.pubTs ?? 0,
      );

  /// 动态条目携带的稿件 bvid，转发原文也算；同一视频只保留一条
  static String? _bvidOf(DynamicItemModel item) =>
      item.videoBvid ?? item.orig?.videoBvid;

  static String _identityOf(DynamicItemModel item) =>
      _bvidOf(item) ?? '${item.idStr}';

  @override
  List<DynamicItemModel> dedupeOnAppend(
    List<DynamicItemModel> existing,
    List<DynamicItemModel> incoming,
  ) {
    // 首页注入的订阅条目在翻页时不能重复出现；正常动态之间保持原顺序
    final subBvids = <String>{
      for (final e in existing)
        if ('${e.idStr}'.startsWith('sub_')) ?_bvidOf(e),
    };
    final seenIds = <String>{for (final e in existing) '${e.idStr}'};
    return incoming.where((e) {
      if (!seenIds.add('${e.idStr}')) return false;
      final bvid = _bvidOf(e);
      return bvid == null || !subBvids.contains(bvid);
    }).toList();
  }

  @override
  Future<LoadingState<DynamicsDataModel>> customGetData() async {
    final res = await DynamicsHttp.followDynamic(
      offset: offset,
      type: dynamicsType,
      hostMid: dynamicsController.hostMid,
      tempBannedList: dynamicsController.tempBannedList,
    );
    // 只在首页合并订阅合集更新；失败完全不影响原有动态列表
    if (offset == null && (dynamicsType == .all || dynamicsType == .video)) {
      if (res case Success(:final response)) {
        try {
          final current = response.items ?? const <DynamicItemModel>[];
          final seen = <String>{for (final e in current) _identityOf(e)};
          final extras = (await SubUpdateHttp.dynamicItems())
              .where((e) => seen.add(_identityOf(e)))
              .toList();
          if (extras.isNotEmpty) {
            response.items = <DynamicItemModel>[
              ...current,
              ...extras,
            ]..sort(_newestFirst);
          }
        } catch (_) {
          // 订阅区块是附加数据，任何异常都不冒泡
        }
      }
    }
    return res;
  }

  Future<void> onRemove(int index, dynamic dynamicId) async {
    final res = await MsgHttp.removeDynamic(dynIdStr: dynamicId);
    if (res.isSuccess) {
      loadingState
        ..value.data!.removeAt(index)
        ..refresh();
      SmartDialog.showToast('删除成功');
    } else {
      res.toast();
    }
  }

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }

  void onBlock(int index) {
    if (dynamicsType != .up) {
      loadingState
        ..value.data!.removeAt(index)
        ..refresh();
    }
  }

  void onUnfold(DynamicItemModel item, int index) {
    final list = loadingState.value.data;
    final ids = item.modules.moduleFold?.ids;
    if (list == null || ids == null) return;
    // 按 id 展开：列表可能被精简模式/充电屏蔽过滤过，位置会错位
    var matched = false;
    for (final e in list) {
      if (ids.contains('${e.idStr}')) {
        matched = true;
        if (!_shouldHide(e)) e.visible = true;
      }
    }
    if (!matched) {
      final end = index + 1 + ids.length;
      for (int i = index + 1; i < end && i < list.length; i++) {
        if (!_shouldHide(list[i])) list[i].visible = true;
      }
    }
    item.modules.moduleFold = null;
    loadingState.refresh();
  }

  @override
  void onChangeAccount(bool isLogin) => onReload();
}
