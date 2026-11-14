import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/sliver_wrap.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/grpc/reply.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class ReplyBlockPage extends StatefulWidget {
  const ReplyBlockPage({super.key});

  @override
  State<ReplyBlockPage> createState() => _ReplyBlockPageState();
}

class _ReplyBlockPageState extends State<ReplyBlockPage> {
  late EdgeInsets padding;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showEditDialog([String? initial]) {
    var text = initial ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? '添加屏蔽词' : '编辑屏蔽词'),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            const Text('每条为正则表达式，同时匹配评论内容与用户名'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: text,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              onChanged: (value) => text = value,
              decoration: const InputDecoration(
                hintText: '如：广告|推广',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: ColorScheme.of(context).outline),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = text.trim();
              if (!ReplyGrpc.isValidRule(value)) {
                SmartDialog.showToast('正则表达式无效');
                return;
              }
              final rules = [...ReplyGrpc.blockRules];
              if (initial == null) {
                if (rules.contains(value)) {
                  SmartDialog.showToast('该屏蔽词已存在');
                  return;
                }
                rules.add(value);
              } else {
                final index = rules.indexOf(initial);
                if (index == -1) return;
                rules[index] = value;
              }
              ReplyGrpc.setBlockRules(rules);
              Get.back();
              _refresh();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String rule) {
    showConfirmDialog(
      context: context,
      title: const Text('删除该屏蔽词？'),
      content: Text(rule),
      onConfirm: () {
        ReplyGrpc.setBlockRules([...ReplyGrpc.blockRules]..remove(rule));
        _refresh();
      },
    );
  }

  void _showImportExportDialog() {
    showImportExportDialog<List>(
      context,
      title: '评论屏蔽词',
      localFileName: () => 'replyBlockRules',
      onExport: () => Utils.jsonEncoder.convert(ReplyGrpc.blockRules),
      onImport: (json) {
        final rules = [...ReplyGrpc.blockRules];
        var skipped = 0;
        for (final e in json) {
          if (e is! String) {
            skipped++;
            continue;
          }
          final value = e.trim();
          if (!ReplyGrpc.isValidRule(value)) {
            skipped++;
            continue;
          }
          if (!rules.contains(value)) rules.add(value);
        }
        ReplyGrpc.setBlockRules(rules);
        _refresh();
        if (skipped > 0) SmartDialog.showToast('已跳过 $skipped 条无效内容');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = ReplyGrpc.blockRules;
    return SimpleScaffold(
      appBar: AppBar(title: const Text('评论屏蔽词')),
      body: ScaffoldLayout(
        fab: Padding(
          padding: .only(
            right: kFloatingActionButtonMargin + padding.right,
            bottom: kFloatingActionButtonMargin + padding.bottom,
          ),
          child: Column(
            spacing: kFloatingActionButtonMargin,
            mainAxisSize: .min,
            children: [
              FloatingActionButton(
                tooltip: '导入/导出',
                onPressed: _showImportExportDialog,
                child: const Icon(Icons.swap_vert, size: 26),
              ),
              FloatingActionButton(
                tooltip: '添加',
                onPressed: _showEditDialog,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const .fromLTRB(12, 12, 12, 4),
                child: Text(
                  '每条为正则表达式，同时匹配评论内容与用户名',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
            ViewSliverSafeArea(
              bottom: 180,
              sliver:
                  rules.isEmpty
                      ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('还未添加屏蔽词')),
                      )
                      : SliverPadding(
                        padding: const .fromLTRB(12, 8, 12, 0),
                        sliver: SliverFixedWrap(
                          spacing: 8,
                          runSpacing: 8,
                          mainAxisExtent: 30,
                          delegate: SliverChildBuilderDelegate(
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false,
                            childCount: rules.length,
                            (context, index) {
                              final rule = rules[index];
                              return SearchText(
                                text: rule,
                                onTap: (_) => _showEditDialog(rule),
                                onLongPress: (_) => _confirmDelete(rule),
                                height: 1,
                                maxLines: 1,
                                fontSize: 14,
                                overflow: .ellipsis,
                                padding: const .fromLTRB(11, 8, 11, 0),
                              );
                            },
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
