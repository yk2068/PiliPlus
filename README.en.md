> [!IMPORTANT]
> **This repository is a fork of [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus), not the official one.**
>
> - Upstream: [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)
> - Fork owner: [yk2068](https://github.com/yk2068)
> - License: **GPL-3.0**, same as upstream (see [LICENSE](LICENSE))
>
> **This fork is an AI-assisted custom build**: changes are generated and maintained with AI assistance (Claude/WorkBuddy), not released by the upstream author.
> Customizations do not represent upstream's position. Please report issues here first; follow the upstream repository for its own progress.

[中文](README.md) | English

## Customizations in this fork

- **One-tap dislike**: a single menu tap submits immediately (no confirmation dialog); tapping again undoes it, and the item label switches to "撤销点踩"
- **Disliked videos hidden everywhere**: once disliked, a video no longer appears in recommendations, hot/rank lists, or related videos
- **Video tag filter**: long-press a tag on the detail page to add it to the filter list (matches partition name exactly, or title by substring); manage the list at Settings → Recommend → 视频标签过滤
- **Two-finger double tap toggles danmaku**: two two-finger presses within 300ms switch danmaku on/off, and the choice is persisted
- **Vertical swipe changes playback speed**: swipe up/down in the center area, one step per 40px; can be turned off in playback settings, which restores the original fullscreen-swipe gesture

## Build

Requires Flutter `3.47.7` (see `pubspec.yaml`), Dart `>=3.13.0`, JDK 17.

```bash
flutter pub get
flutter build apk --debug          # debug build, no signing needed
flutter build apk --release        # requires android/key.properties
```

Patch the Flutter SDK before building for Android (same as upstream CI):

```bash
pwsh lib/scripts/patch.ps1 android
```

Every push triggers `.github/workflows/verify.yml` for cloud build verification (pub get → analyze → build apk).

## Disclaimer

PiliPlus is a personal project developed out of interest, for learning and testing only. Please delete it within 24 hours after downloading.
All APIs are collected from the official site; no cracked content is provided.

Credits to the upstream authors: [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus),
[orz12/PiliPalaX](https://github.com/orz12/PiliPalaX),
[guozhigq/pilipala](https://github.com/guozhigq/pilipala).
