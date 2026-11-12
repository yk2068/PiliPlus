/// B 站各接口标记充电专属视频的字段不统一：
/// 推荐 / 热门 / 排行 / 稍后再看是 charging_pay，空间投稿 / 搜索是
/// is_charging_arc，视频详情是 is_upower_exclusive，动态卡片是 badge.text。
abstract final class ChargingVideo {
  static bool isChargingText(String? text) =>
      text != null && text.contains('充电');

  static bool fromJson(dynamic json) {
    if (json is! Map) return false;
    final chargingPay = json['charging_pay'];
    if ((chargingPay is Map && chargingPay['level'] != null) ||
        json['is_charging_arc'] == true ||
        json['is_charging_arc'] == 1 ||
        json['is_upower_exclusive'] == true ||
        json['is_charging'] == true) {
      return true;
    }
    final badge = json['badge'];
    if (badge is String) return isChargingText(badge);
    if (badge is Map) return isChargingText(badge['text']?.toString());
    return false;
  }

  /// 动态的 major 下挂多种卡片，充电内容也可能出现在转发原文里
  static bool fromDynamicJson(dynamic json) {
    if (json is! Map) return false;
    if (_isChargingType(json['type'])) return true;
    final modules = json['modules'];
    if (modules is Map) {
      final tag = modules['module_tag'];
      if (tag is Map && isChargingText(tag['text']?.toString())) return true;
      final major = modules['module_dynamic']?['major'];
      if (major is Map) {
        if (_isChargingType(major['type'])) return true;
        for (final value in major.values) {
          if (fromJson(value)) return true;
        }
      }
    }
    return fromDynamicJson(json['orig']);
  }

  static bool _isChargingType(dynamic type) {
    final text = type?.toString().toLowerCase();
    return text != null && (text.contains('upower') || text.contains('charge'));
  }
}
