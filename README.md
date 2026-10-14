> [!IMPORTANT]
> **本仓库是 [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 的 Fork，并非官方仓库。**
>
> - 上游项目：[bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)
> - 本 Fork 所有者：[yk2068](https://github.com/yk2068)
> - 许可：沿用上游的 **GPL-3.0**（见 [LICENSE](LICENSE)）
>
> **本 Fork 为 AI 辅助定制版本**：改动由 AI（Claude/WorkBuddy）辅助生成与维护，非上游作者官方发布。
> 定制内容不代表上游立场，问题与 bug 请优先在本仓库反馈；如需跟随上游进展，可关注上游仓库。

## 本 Fork 的定制内容

- **点踩一步到位**：菜单点一次直接提交，不再二次确认；已点踩再点即撤销，菜单项文案变为「撤销点踩」
- **点踩过的视频全场景屏蔽**：点踩后的视频不再出现在推荐、热门、排行、相关推荐中
- **视频标签过滤**：详情页长按标签即可加入过滤名单（按分区名精确匹配 + 标题包含匹配）；名单管理入口在「设置 → 推荐设置 → 视频标签过滤」
- **双指双击开关弹幕**：播放器内两次双指按下（间隔 ≤300ms）切换弹幕开关，并写入设置持久化
- **上下滑动切换倍速**：播放器中间区域上下滑动调速，每 40px 换一档；可在「播放设置」中关闭，关闭后该区域恢复为原来的全屏切换手势

## 构建

要求 Flutter `3.47.7`（见 `pubspec.yaml`）、Dart `>=3.13.0`、JDK 17。

```bash
flutter pub get
flutter build apk --debug          # 调试包，无需签名
flutter build apk --release        # 需自行配置 android/key.properties
```

Android 构建前需先给 Flutter SDK 打补丁（与上游 CI 一致）：

```bash
pwsh lib/scripts/patch.ps1 android
```

每次 push 会触发 `.github/workflows/verify.yml` 做云端编译验证（pub get → analyze → build apk）。

## 声明

此项目（PiliPlus）是个人为了兴趣而开发，仅用于学习和测试，请于下载后 24 小时内删除。
所用 API 皆从官方网站收集，不提供任何破解内容。

在此致敬上游作者：[bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)、
[orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)、
[guozhigq/pilipala](https://github.com/guozhigq/pilipala)。
