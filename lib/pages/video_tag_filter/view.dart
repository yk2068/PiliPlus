import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 视频标签过滤名单管理
///
/// 添加方式：视频详情页长按标签。
/// 列表接口不返回视频 tag，因此按「分区名精确匹配 + 标题包含」来判断是否命中。
class VideoTagFilterPage extends StatefulWidget {
  const VideoTagFilterPage({super.key});

  @override
  State<VideoTagFilterPage> createState() => _VideoTagFilterPageState();
}

class _VideoTagFilterPageState extends State<VideoTagFilterPage> {
  final Set<String> _tags = GlobalData().videoTagFilter;
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<bool?> _confirm({
    required String title,
    String content = '',
    String confirmText = '确定',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: content.isEmpty
            ? null
            : Text(
                content,
                style: TextStyle(color: ColorScheme.of(context).outline),
              ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    _inputController.clear();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签过滤'),
        content: TextField(
          controller: _inputController,
          autofocus: true,
          textInputAction: .done,
          decoration: const InputDecoration(
            hintText: '标签名',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: _inputController.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    final tag = text?.trim();
    if (tag == null || tag.isEmpty) return;
    if (_tags.contains(tag)) {
      SmartDialog.showToast('该标签已在过滤名单中');
      return;
    }
    Pref.addVideoTagFilter(tag);
    _refresh();
    SmartDialog.showToast('已添加：$tag');
  }

  Future<void> _onRemove(String tag) async {
    if (await _confirm(
          title: '移除该标签？',
          content: tag,
          confirmText: '移除',
        ) !=
        true) {
      return;
    }
    Pref.removeVideoTagFilter(tag);
    _refresh();
    SmartDialog.showToast('已移除：$tag');
  }

  Future<void> _onClearAll() async {
    if (_tags.isEmpty) return;
    if (await _confirm(
          title: '清空全部标签过滤？',
          confirmText: '清空',
        ) !=
        true) {
      return;
    }
    Pref.videoTagFilter = <String>{};
    _tags.clear();
    _refresh();
    SmartDialog.showToast('已清空');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outlineStyle = TextStyle(fontSize: 13, color: colorScheme.outline);

    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('视频标签过滤'),
        actions: [
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.clear_all),
            onPressed: _onClearAll,
          ),
        ],
      ),
      fab: FloatingActionButton(
        tooltip: '添加标签',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _tags.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Icon(Icons.tag, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    '暂无过滤标签',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text('在视频详情页长按标签即可添加', style: outlineStyle),
                ],
              ),
            )
          : ListView(
              padding: const .fromLTRB(12, 12, 12, 88),
              children: [
                Padding(
                  padding: const .only(bottom: 12),
                  child: Text(
                    '共 ${_tags.length} 个标签。命中分区名或标题的视频，将从推荐、热门、排行、相关推荐中移除。',
                    style: outlineStyle,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags
                      .map(
                        (tag) => SearchText(
                          text: tag,
                          fontSize: 14,
                          onTap: (_) => Get.toNamed(
                            '/searchResult',
                            parameters: {'keyword': tag},
                          ),
                          onLongPress: (_) => _onRemove(tag),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}
