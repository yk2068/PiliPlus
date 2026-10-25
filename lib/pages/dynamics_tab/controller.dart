import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
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
      if ((Pref.blockChargingVideo && item.isChargingVideo) ||
          (GlobalData().dynCompact && !item.isVideoDynamic)) {
        item.visible = false;
      }
    }
    return items;
  }

  @override
  Future<LoadingState<DynamicsDataModel>> customGetData() =>
      DynamicsHttp.followDynamic(
        offset: offset,
        type: dynamicsType,
        hostMid: dynamicsController.hostMid,
        tempBannedList: dynamicsController.tempBannedList,
      );

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
        e.visible = true;
        matched = true;
      }
    }
    if (!matched) {
      final end = index + 1 + ids.length;
      for (int i = index + 1; i < end && i < list.length; i++) {
        list[i].visible = true;
      }
    }
    item.modules.moduleFold = null;
    loadingState.refresh();
  }

  @override
  void onChangeAccount(bool isLogin) => onReload();
}
