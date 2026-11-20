import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models_new/sub/sub/data.dart';
import 'package:PiliPlus/models_new/sub/sub/list.dart';
import 'package:PiliPlus/models_new/sub/sub_detail/data.dart';
import 'package:PiliPlus/models_new/sub/sub_detail/media.dart';
import 'package:PiliPlus/utils/accounts.dart';

/// 把「我的订阅」里各合集的最新稿件包装成标准 DYNAMIC_TYPE_AV 动态条目，
/// 混入动态列表，普通模式与精简模式的视频卡片都能直接显示。
abstract final class SubUpdateHttp {
  static List<_Video>? _cache;
  static DateTime? _cacheAt;

  /// 缓存 60 秒，避免「全部」「投稿」两个 tab 各自重复拉一遍。
  /// 每次返回全新的 DynamicItemModel，避免多个列表共享同一个对象被改 visible。
  static Future<List<DynamicItemModel>> dynamicItems({
    int maxSeason = 8,
    int perSeason = 2,
    int limit = 8,
  }) async {
    final now = DateTime.now();
    List<_Video> videos;
    if (_cache != null &&
        _cacheAt != null &&
        now.difference(_cacheAt!) < const Duration(seconds: 60)) {
      videos = _cache!;
    } else {
      try {
        videos = await _build(maxSeason, perSeason, limit);
        _cache = videos;
        _cacheAt = now;
      } catch (_) {
        return const <DynamicItemModel>[];
      }
    }
    return videos.map(_toDynamic).toList();
  }

  static Future<List<_Video>> _build(
    int maxSeason,
    int perSeason,
    int limit,
  ) async {
    final account = Accounts.main;
    if (!account.isLogin) return const <_Video>[];

    final res = await UserHttp.userSubFolder(mid: account.mid, pn: 1, ps: 20);
    if (res is! Success<SubData>) return const <_Video>[];
    final all = res.response.list ?? const <SubItemModel>[];
    // type 11 是收藏夹，其余为合集
    final subs = all
        .where((e) => e.id != null && e.type != null && e.type != 11)
        .take(maxSeason)
        .toList();
    if (subs.isEmpty) return const <_Video>[];

    final groups = await Future.wait(subs.map((e) => _fetch(e, perSeason)));
    final videos = groups.expand((e) => e).toList()
      ..sort((a, b) => b.pubdate.compareTo(a.pubdate));

    final seen = <String>{};
    final items = <_Video>[];
    for (final v in videos) {
      if (!seen.add(v.bvid)) continue;
      items.add(v);
      if (items.length >= limit) break;
    }
    return items;
  }

  /// 合集作者在两条接口里完全相同，只算一次再复用
  static ({String season, String upper, int? mid, String face}) _subMeta(
    SubItemModel sub,
  ) => (
    season: sub.title ?? '',
    upper: sub.upper?.name ?? '',
    mid: sub.upper?.mid,
    face: sub.upper?.face ?? '',
  );

  static String _https(String cover) =>
      cover.replaceFirst('http://', 'https://');

  /// 两条接口并发取，按 bvid 去重后按发布时间排序
  static Future<List<_Video>> _fetch(SubItemModel sub, int perSeason) async {
    final results = await Future.wait([
      _bySpaceArchives(sub, perSeason),
      _byFavSeason(sub),
    ]);
    final seen = <String>{};
    final merged = <_Video>[];
    for (final group in results) {
      for (final v in group) {
        if (seen.add(v.bvid)) merged.add(v);
      }
    }
    merged.sort((a, b) => b.pubdate.compareTo(a.pubdate));
    return merged.take(perSeason).toList();
  }

  /// 空间合集接口：sort_reverse=true 即最新在前，不需要 mid
  static Future<List<_Video>> _bySpaceArchives(
    SubItemModel sub,
    int perSeason,
  ) async {
    try {
      final res = await Request().get(
        Api.seasonArchives,
        queryParameters: {
          'season_id': sub.id,
          'sort_reverse': true,
          'page_num': 1,
          'page_size': perSeason,
          'web_location': 333.1387,
        },
      );
      final data = res.data;
      if (data is! Map || data['code'] != 0) return const <_Video>[];
      final archives = data['data']?['archives'];
      if (archives is! List) return const <_Video>[];
      final meta = _subMeta(sub);
      return archives
          .map((e) {
            final stat = e['stat'] as Map?;
            return _Video(
              bvid: e['bvid'] as String? ?? '',
              aid: e['aid'],
              title: e['title'] as String? ?? '',
              cover: _https(e['pic'] as String? ?? ''),
              pubdate: (e['pubdate'] as int?) ?? 0,
              duration: (e['duration'] as int?) ?? 0,
              play: stat?['view']?.toString() ?? '0',
              danmaku: stat?['danmaku']?.toString() ?? '0',
              season: meta.season,
              upper: meta.upper,
              mid: meta.mid,
              face: meta.face,
            );
          })
          .where((e) => e.bvid.isNotEmpty)
          .toList();
    } catch (_) {
      return const <_Video>[];
    }
  }

  /// 订阅详情页同款接口，作为兜底
  static Future<List<_Video>> _byFavSeason(SubItemModel sub) async {
    try {
      final res = await FavHttp.favSeasonList(id: sub.id!, pn: 1, ps: 30);
      if (res is! Success<SubDetailData>) return const <_Video>[];
      final medias = res.response.medias ?? const <SubDetailItemModel>[];
      final meta = _subMeta(sub);
      return medias
          .where((e) => e.bvid?.isNotEmpty == true)
          .map(
            (e) => _Video(
              bvid: e.bvid!,
              aid: e.id,
              title: e.title ?? '',
              cover: _https(e.cover ?? ''),
              pubdate: e.pubtime ?? 0,
              duration: e.duration ?? 0,
              play: e.cntInfo?.play?.toString() ?? '0',
              danmaku: e.cntInfo?.danmaku?.toString() ?? '0',
              season: meta.season,
              upper: meta.upper,
              mid: meta.mid,
              face: meta.face,
            ),
          )
          .toList()
        ..sort((a, b) => b.pubdate.compareTo(a.pubdate));
    } catch (_) {
      return const <_Video>[];
    }
  }

  /// 用项目自带的解析器构造完整动态条目，确保所有卡片组件需要的字段都在
  static DynamicItemModel _toDynamic(_Video v) {
    // 合集名做角标；含充电关键词会被误判成充电视频，改用固定文案
    final badgeText = (v.season.contains('充电') || v.season.contains('抢先看'))
        ? '订阅更新'
        : (v.season.isEmpty ? '订阅更新' : v.season);
    return DynamicItemModel.fromJson({
      'id_str': 'sub_${v.bvid}',
      'type': 'DYNAMIC_TYPE_AV',
      'visible': true,
      'basic': {
        'comment_id_str': v.aid?.toString() ?? v.bvid,
        'comment_type': 1,
        'rid_str': v.aid?.toString() ?? v.bvid,
      },
      'modules': {
        'module_author': {
          'mid': v.mid,
          'name': v.upper,
          'face': v.face,
          'pub_ts': v.pubdate,
          'pub_time': '',
          'pub_action': '投稿了视频',
          'type': 'AUTHOR_TYPE_NORMAL',
        },
        'module_dynamic': {
          'major': {
            'type': 'MAJOR_TYPE_ARCHIVE',
            'archive': {
              'bvid': v.bvid,
              'aid': v.aid,
              'title': v.title,
              'cover': v.cover,
              'duration_text': _durationText(v.duration),
              'type': 0,
              'badge': {'text': badgeText},
              'stat': {'play': v.play, 'danmaku': v.danmaku},
              'jump_url': 'https://www.bilibili.com/video/${v.bvid}',
            },
          },
        },
        // 普通模式的 ActionPanel 对这三个有强解引用，必须给全
        'module_stat': {
          'comment': {'count': 0, 'status': false},
          'forward': {'count': 0, 'status': false},
          'like': {'count': 0, 'status': false},
        },
      },
    });
  }

  static String _durationText(int sec) {
    if (sec <= 0) return '';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _Video {
  const _Video({
    required this.bvid,
    required this.aid,
    required this.title,
    required this.cover,
    required this.pubdate,
    required this.duration,
    required this.play,
    required this.danmaku,
    required this.season,
    required this.upper,
    required this.mid,
    required this.face,
  });

  final String bvid;
  final dynamic aid;
  final String title;
  final String cover;
  final int pubdate;
  final int duration;
  final String play;
  final String danmaku;
  final String season;
  final String upper;
  final int? mid;
  final String face;
}
