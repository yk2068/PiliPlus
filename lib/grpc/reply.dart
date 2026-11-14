import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart';
import 'package:PiliPlus/grpc/bilibili/pagination.pb.dart';
import 'package:PiliPlus/grpc/grpc_req.dart';
import 'package:PiliPlus/grpc/url.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/reply_filter.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:fixnum/fixnum.dart';

abstract final class ReplyGrpc {
  static bool antiGoodsReply = Pref.antiGoodsReply;

  /// 评论内容屏蔽词，每条是独立的正则表达式
  static List<String> blockRules = _loadRules(false);
  static List<RegExp> _blockRegExps = ReplyFilter.compile(blockRules);

  /// 用户名屏蔽词，与内容规则分开匹配
  static List<String> userBlockRules = _loadRules(true);
  static List<RegExp> _userBlockRegExps = ReplyFilter.compile(userBlockRules);

  static bool get enableFilter =>
      _blockRegExps.isNotEmpty || _userBlockRegExps.isNotEmpty;

  static List<String> _loadRules(bool forUser) {
    final key = forUser
        ? SettingBoxKey.replyUserBlockRules
        : SettingBoxKey.replyBlockRules;
    final stored = GStorage.setting.get(key);
    if (stored is List) {
      return stored.whereType<String>().where((e) => e.isNotEmpty).toList();
    }
    if (forUser) return <String>[];
    // 旧版本把全部规则塞在一个正则字符串里，首次读取时迁移成一条规则
    final legacy = Pref.banWordForReply;
    final rules = legacy.isEmpty ? <String>[] : [legacy];
    if (rules.isNotEmpty) {
      GStorage.setting.put(key, rules);
    }
    return rules;
  }

  static bool isValidRule(String pattern) => ReplyFilter.isValidRule(pattern);

  static void setBlockRules(List<String> rules, {bool forUser = false}) {
    final list = rules
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && isValidRule(e))
        .toSet()
        .toList();
    final regExps = ReplyFilter.compile(list);
    if (forUser) {
      userBlockRules = list;
      _userBlockRegExps = regExps;
    } else {
      blockRules = list;
      _blockRegExps = regExps;
    }
    GStorage.setting.put(
      forUser
          ? SettingBoxKey.replyUserBlockRules
          : SettingBoxKey.replyBlockRules,
      list,
    );
  }

  static bool addBlockRule(String pattern, {bool forUser = false}) {
    final current = forUser ? userBlockRules : blockRules;
    if (!isValidRule(pattern) || current.contains(pattern)) return false;
    setBlockRules([...current, pattern], forUser: forUser);
    return true;
  }

  static bool isBlocked(String message, String name) => ReplyFilter.isBlocked(
    _blockRegExps,
    _userBlockRegExps,
    message,
    name,
  );

  // static Future replyInfo({required int rpid}) {
  //   return _request(
  //     GrpcUrl.replyInfo,
  //     ReplyInfoReq(rpid: Int64(rpid)),
  //     ReplyInfoReply.fromBuffer,
  //     onSuccess: (response) => response.reply,
  //   );
  // }

  // ref BiliRoamingX
  static bool needRemoveGoodGrpc(ReplyInfo reply) {
    return (reply.content.urls.isNotEmpty &&
            reply.content.urls.values.any((url) {
              return url.hasExtra() &&
                  (url.extra.goodsCmControl == Int64.ONE ||
                      url.extra.hasGoodsItemId() ||
                      url.extra.hasGoodsPrefetchedCache());
            })) ||
        reply.content.message.contains(Constants.goodsUrlPrefix);
  }

  static bool needRemoveGrpc(ReplyInfo reply) {
    return GlobalData().blackMids.contains(reply.mid.toInt()) ||
        isBlocked(reply.content.message, reply.member.name) ||
        (antiGoodsReply && needRemoveGoodGrpc(reply));
  }

  static Future<LoadingState<MainListReply>> mainList({
    int type = 1,
    required int oid,
    required Mode mode,
    required String? offset,
    required Int64? cursorNext,
  }) async {
    final res = await GrpcReq.request(
      GrpcUrl.mainList,
      MainListReq(
        oid: Int64(oid),
        type: Int64(type),
        rpid: Int64.ZERO,
        cursor: CursorReq(
          mode: mode,
          next: cursorNext,
        ),
        // mode: mode,
        // pagination: offset == null ? null : FeedPagination(offset: offset),
      ),
      MainListReply.fromBuffer,
    );
    if (res case Success(:final response)) {
      // keyword filter
      if (response.hasUpTop() && needRemoveGrpc(response.upTop)) {
        response.clearUpTop();
      }

      if (response.replies.isNotEmpty) {
        response.replies.removeWhere((item) {
          final hasMatch = needRemoveGrpc(item);
          if (!hasMatch && item.replies.isNotEmpty) {
            item.replies.removeWhere(needRemoveGrpc);
          }
          return hasMatch;
        });
      }
    }
    return res;
  }

  static Future<LoadingState<DetailListReply>> detailList({
    int type = 1,
    required int oid,
    required int root,
    required int rpid,
    required Mode mode,
    required String? offset,
  }) async {
    final res = await GrpcReq.request(
      GrpcUrl.detailList,
      DetailListReq(
        oid: Int64(oid),
        type: Int64(type),
        root: Int64(root),
        rpid: Int64(rpid),
        scene: DetailListScene.REPLY,
        mode: mode,
        pagination: offset == null ? null : FeedPagination(offset: offset),
      ),
      DetailListReply.fromBuffer,
    );
    return res..dataOrNull?.root.replies.removeWhere(needRemoveGrpc);
  }

  static Future<LoadingState<DialogListReply>> dialogList({
    int type = 1,
    required int oid,
    required int root,
    required int dialog,
    required String? offset,
  }) async {
    final res = await GrpcReq.request(
      GrpcUrl.dialogList,
      DialogListReq(
        oid: Int64(oid),
        type: Int64(type),
        root: Int64(root),
        dialog: Int64(dialog),
        pagination: offset == null ? null : FeedPagination(offset: offset),
      ),
      DialogListReply.fromBuffer,
    );
    return res..dataOrNull?.replies.removeWhere(needRemoveGrpc);
  }

  static Future<LoadingState<SearchItemReply>> searchItem({
    required int page,
    required SearchItemType itemType,
    required int oid,
    int type = 1,
    String? keyword,
  }) {
    return GrpcReq.request(
      GrpcUrl.searchItem,
      SearchItemReq(
        cursor: SearchItemCursorReq(
          next: Int64(page),
          itemType: itemType,
        ),
        oid: Int64(oid),
        type: Int64(type),
        keyword: keyword,
      ),
      SearchItemReply.fromBuffer,
    );
  }

  static Future<LoadingState<TranslateReplyResp>> translateReply({
    required Int64 type,
    required Int64 oid,
    required Int64 rpid,
  }) {
    return GrpcReq.request(
      GrpcUrl.translateReply,
      TranslateReplyReq(
        type: type,
        oid: oid,
        rpids: [rpid],
      ),
      TranslateReplyResp.fromBuffer,
    );
  }
}
