import 'dart:convert' show utf8;
import 'dart:io' show Directory, File;
import 'dart:typed_data' show Uint8List;

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/dialog/simple_dialog_option.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/models_new/video/video_play_info/subtitle.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/path_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_utils.dart';
import 'package:PiliPlus/utils/subtitle_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;

/// 把当前播放的视频的音轨、字幕另存为独立文件
abstract final class MediaExport {
  static const _referer = 'https://www.bilibili.com/';
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// 下载音频
  static void saveAudio(
    BuildContext context,
    VideoDetailController ctr, {
    required String title,
  }) {
    final audioMap = <int, AudioItem>{};
    final List<AudioItem> audioList;
    try {
      audioList = ctr.data.dash?.audio ?? const <AudioItem>[];
    } catch (_) {
      SmartDialog.showToast('视频信息未加载完成');
      return;
    }
    for (final item in audioList) {
      final old = audioMap[item.id];
      if (old == null || (item.bandWidth ?? 0) > (old.bandWidth ?? 0)) {
        audioMap[item.id] = item;
      }
    }
    if (audioMap.isEmpty) {
      SmartDialog.showToast('当前视频没有可下载的音轨');
      return;
    }
    final sorted = audioMap.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    final secondary = ColorScheme.of(context).secondary;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        clipBehavior: Clip.hardEdge,
        title: const Text('下载音频'),
        children: List.generate(sorted.length, (i) {
          final item = sorted[i];
          return DialogOption(
            onPressed: () {
              Get.back();
              _downloadAudio(ctr, item, title);
            },
            child: Row(
              children: [
                Expanded(child: Text(item.quality)),
                if (item.bandWidth case final bandwidth?)
                  Text(
                    '${(bandwidth / 1000).round()} Kbps',
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  static Future<void> _downloadAudio(
    VideoDetailController ctr,
    AudioItem item,
    String title,
  ) async {
    final url = VideoUtils.getCdnUrl(item.playUrls, isAudio: true);
    if (url.isEmpty) {
      SmartDialog.showToast('音轨地址为空');
      return;
    }
    // 统一存成 m4a，文件名直接用视频标题
    final base = _sanitize(title);
    final name =
        '${base.length > 80 ? base.substring(0, 80) : base}.m4a';
    final dstPath = await _destPath(name);
    if (dstPath == null) return;

    SmartDialog.showLoading(msg: '正在下载音频');
    try {
      await Request.dio.download(
        url.http2https,
        dstPath,
        options: Options(
          headers: {'referer': _referer, 'user-agent': _userAgent},
        ),
      );
      SmartDialog.dismiss(status: SmartStatus.loading);
      SmartDialog.showToast('已保存至 $dstPath');
    } catch (e, s) {
      Utils.reportError(e, s);
      SmartDialog.dismiss(status: SmartStatus.loading);
      SmartDialog.showToast('下载失败：$e');
    }
  }

  /// 下载字幕
  static void saveSubtitle(
    BuildContext context,
    VideoDetailController ctr, {
    required String title,
  }) {
    final subtitles = ctr.subtitles;
    if (subtitles.isEmpty) {
      SmartDialog.showToast('当前视频没有可下载的字幕');
      return;
    }
    SubtitleFormat format = .srt;
    final secondary = ColorScheme.of(context).secondary;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        clipBehavior: Clip.hardEdge,
        contentPadding: const .only(bottom: 12),
        titlePadding: const .fromLTRB(20, 20, 20, 12),
        title: Row(
          children: [
            const Expanded(child: Text('下载字幕')),
            const Text('格式: ', style: TextStyle(fontSize: 14)),
            Builder(
              builder: (context) => PopupMenuButton<SubtitleFormat>(
                tooltip: '',
                initialValue: format,
                onSelected: (value) {
                  format = value;
                  (context as Element).markNeedsBuild();
                },
                itemBuilder: (_) => SubtitleFormat.values
                    .map(
                      (e) => PopupMenuItem(
                        value: e,
                        height: 35,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                child: Padding(
                  padding: const .symmetric(horizontal: 2, vertical: 5),
                  child: Text(
                    format.label,
                    style: TextStyle(fontSize: 14, color: secondary),
                  ),
                ),
              ),
            ),
          ],
        ),
        children: List.generate(subtitles.length, (i) {
          final item = subtitles[i];
          return DialogOption(
            onPressed: () async {
              Get.back();
              final bytes = await _loadSubtitle(item, format);
              if (bytes == null) return;
              StorageUtils.saveBytes2File(
                name: _sanitize(
                  '$title-${ctr.bvid}-${ctr.cid.value}-'
                  '${item.lanDoc ?? item.lan}.${format.name}',
                ),
                bytes: bytes,
                allowedExtensions: [format.name],
              );
            },
            child: Text(item.lanDoc ?? item.lan),
          );
        }),
      ),
    );
  }

  static Future<Uint8List?> _loadSubtitle(
    Subtitle item,
    SubtitleFormat format,
  ) async {
    final url = item.subtitleUrl;
    if (url == null || url.isEmpty) {
      SmartDialog.showToast('字幕链接无效');
      return null;
    }
    try {
      if (format == .json) {
        final res = await Request.dio.get<Uint8List>(
          url.http2https,
          options: Options(
            responseType: .bytes,
            headers: Constants.baseHeaders,
            extra: {'account': const NoAccount()},
          ),
        );
        if (res.statusCode != 200) {
          SmartDialog.showToast('字幕获取失败');
          return null;
        }
        return Uint8List.fromList(
          Request.responseBytesDecoder(res.data!, res.headers.map),
        );
      }
      final text = await VideoHttp.getSubtitles(url, format: format);
      if (text == null) {
        SmartDialog.showToast('字幕获取失败');
        return null;
      }
      return utf8.encode(text);
    } catch (e, s) {
      Utils.reportError(e, s);
      SmartDialog.showToast('字幕获取失败：$e');
    }
    return null;
  }

  /// 桌面端选目录，移动端落到缓存目录下的 export 文件夹
  static Future<String?> _destPath(String name) async {
    late final String dirPath;
    if (PlatformUtils.isDesktop) {
      final dir = await FilePicker.getDirectoryPath();
      if (dir == null) {
        SmartDialog.showToast('取消保存');
        return null;
      }
      dirPath = dir;
    } else {
      final dir = Directory(path.join(downloadPath, 'export'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      dirPath = dir.path;
    }
    var dstPath = path.join(dirPath, name);
    if (File(dstPath).existsSync()) {
      final base = dstPath.substring(0, dstPath.lastIndexOf('.'));
      final ext = dstPath.substring(dstPath.lastIndexOf('.'));
      for (var i = 1; ; i++) {
        dstPath = '$base($i)$ext';
        if (!File(dstPath).existsSync()) break;
      }
    }
    return dstPath;
  }

  static final _illegalChars = RegExp(r'[<>:/\\|?*"]');

  static String _sanitize(String name) => name
      .replaceAll(_illegalChars, '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
