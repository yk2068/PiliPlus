import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:material_ui/material_ui.dart';

/// 记录用户最近用过的设置项，按使用时间倒序，供「常用设置」页展示。
///
/// 存的是「分组序号:项序号」，取值时回到 [SettingType.settings] 里定位，
/// 越界的记录直接丢弃，设置项增删不会导致错位。
class RecentSettings {
  static const _max = 20;

  /// 手指按下的位置与抬起位置的容差，超出即认为是在滚动列表。
  static const _tapSlop = 12.0;

  static List<(SettingType, int)> load() {
    final raw = GStorage.setting.get(
      SettingBoxKey.recentSettings,
      defaultValue: '',
    );
    if (raw is! String || raw.isEmpty) return [];
    final result = <(SettingType, int)>[];
    for (final part in raw.split(',')) {
      final split = part.split(':');
      if (split.length != 2) continue;
      final typeIndex = int.tryParse(split[0]);
      final itemIndex = int.tryParse(split[1]);
      if (typeIndex == null || itemIndex == null) continue;
      if (typeIndex < 0 || typeIndex >= SettingType.values.length) continue;
      final type = SettingType.values[typeIndex];
      if (!type.hasSettings) continue;
      if (itemIndex < 0 || itemIndex >= type.settings.length) continue;
      final item = (type, itemIndex);
      if (result.contains(item)) continue;
      result.add(item);
    }
    return result;
  }

  static void touch(SettingType type, int index) {
    if (!type.hasSettings) return;
    if (index < 0 || index >= type.settings.length) return;
    final list = load()
      ..removeWhere((e) => e.$1 == type && e.$2 == index)
      ..insert(0, (type, index));
    if (list.length > _max) list.length = _max;
    GStorage.setting.put(
      SettingBoxKey.recentSettings,
      list.map((e) => '${e.$1.index}:${e.$2}').join(','),
    );
  }

  /// 判断一次按下-抬起是否算点击，滚动列表时位移会明显超限。
  static bool isTap(Offset down, Offset up) => (up - down).distance <= _tapSlop;
}

/// 包在设置项外面，点击时把该项记进「常用设置」。滑动列表不记录。
class RecentSettingTracker extends StatefulWidget {
  const RecentSettingTracker({
    super.key,
    required this.type,
    required this.index,
    required this.child,
  });

  final SettingType type;
  final int index;
  final Widget child;

  @override
  State<RecentSettingTracker> createState() => _RecentSettingTrackerState();
}

class _RecentSettingTrackerState extends State<RecentSettingTracker> {
  Offset? _downPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _downPosition = event.position,
      onPointerUp: (event) {
        final down = _downPosition;
        _downPosition = null;
        if (down == null) return;
        if (!RecentSettings.isTap(down, event.position)) return;
        RecentSettings.touch(widget.type, widget.index);
      },
      onPointerCancel: (_) => _downPosition = null,
      child: widget.child,
    );
  }
}

class RecentSettingPage extends StatefulWidget {
  const RecentSettingPage({super.key});

  @override
  State<RecentSettingPage> createState() => _RecentSettingPageState();
}

class _RecentSettingPageState extends State<RecentSettingPage> {
  late final List<(SettingType, int)> _items = RecentSettings.load();

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text('常用设置')),
      body: _items.isEmpty
          ? Center(
              child: Text(
                '还没有用过设置项\n去各个分组里点点看',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorScheme.of(context).outline),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
                bottom: padding.bottom + 100,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final (type, itemIndex) = _items[index];
                return RecentSettingTracker(
                  type: type,
                  index: itemIndex,
                  child: type.settings[itemIndex].widget,
                );
              },
            ),
    );
  }
}
