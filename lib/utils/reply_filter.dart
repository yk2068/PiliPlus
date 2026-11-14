/// 评论屏蔽词：每条是独立正则，同时匹配评论内容与用户名
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
    List<RegExp> regExps,
    String message,
    String name,
  ) {
    if (regExps.isEmpty) return false;
    return regExps.any(
      (regExp) =>
          regExp.hasMatch(message) ||
          (name.isNotEmpty && regExp.hasMatch(name)),
    );
  }
}
