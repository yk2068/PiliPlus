/// 评论屏蔽词：评论内容与用户名各用一组独立的正则，互不串用
abstract final class ReplyFilter {
  static bool isValidRule(String pattern) {
    if (pattern.isEmpty) return false;
    try {
      RegExp(pattern, caseSensitive: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<RegExp> compile(Iterable<String> rules) {
    final regExps = <RegExp>[];
    for (final rule in rules) {
      try {
        regExps.add(RegExp(rule, caseSensitive: false));
      } catch (_) {}
    }
    return regExps;
  }

  static bool isBlocked(
    List<RegExp> contentRegExps,
    List<RegExp> userRegExps,
    String message,
    String name,
  ) {
    if (contentRegExps.any((regExp) => regExp.hasMatch(message))) {
      return true;
    }
    if (name.isEmpty || userRegExps.isEmpty) return false;
    return userRegExps.any((regExp) => regExp.hasMatch(name));
  }
}
