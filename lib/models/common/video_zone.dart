/// B 站视频分区常量（主分区 + 子分区 tid 映射）
///
/// 用于「自动一倍速分区」：用户勾选主分区（大区），
/// 判定时把视频详情接口返回的 `tid`（具体子分区）映射回主分区。
library;

/// 主分区（大区）信息
class VideoZone {
  final int tid;
  final String name;

  /// 该主分区下的所有子分区 tid
  final Set<int> children;

  const VideoZone(this.tid, this.name, this.children);
}

/// 主分区列表（按官方顺序）
const List<VideoZone> videoZones = [
  VideoZone(1, '动画', {24, 25, 47, 257, 210, 86, 253, 27}),
  VideoZone(13, '番剧', {51, 152, 32, 33}),
  VideoZone(167, '国创', {153, 168, 169, 170, 195}),
  VideoZone(3, '音乐', {
    28, 29, 31, 59, 243, 30, 193, 266, 265, 267, 244, 130, 194,
  }),
  VideoZone(129, '舞蹈', {20, 198, 199, 200, 255, 154, 156}),
  VideoZone(4, '游戏', {17, 171, 172, 65, 173, 121, 136, 19}),
  VideoZone(36, '知识', {201, 124, 228, 207, 208, 209, 229, 122, 39, 96, 98}),
  VideoZone(188, '科技', {95, 230, 231, 232, 233, 189, 190, 191}),
  VideoZone(234, '运动', {235, 249, 164, 236, 237, 238}),
  VideoZone(223, '汽车', {
    258, 227, 247, 245, 246, 240, 248, 176, 224, 225, 226,
  }),
  VideoZone(160, '生活', {
    138, 254, 250, 251, 239, 161, 162, 21, 76, 75, 163, 176, 174,
  }),
  VideoZone(211, '美食', {76, 212, 213, 214, 215}),
  VideoZone(217, '动物圈', {218, 219, 222, 221, 220, 75}),
  VideoZone(119, '鬼畜', {22, 26, 126, 216, 127}),
  VideoZone(155, '时尚', {157, 252, 158, 159, 164, 192}),
  VideoZone(202, '资讯', {203, 204, 205, 206}),
  VideoZone(5, '娱乐', {241, 262, 263, 242, 264, 137, 71, 131}),
  VideoZone(181, '影视', {182, 183, 260, 259, 184, 85, 256, 261}),
  VideoZone(177, '纪录片', {37, 178, 179, 180}),
  VideoZone(23, '电影', {147, 145, 146, 83}),
  VideoZone(11, '电视剧', {185, 187}),
];

/// 把子分区 tid 映射到所属主分区 tid；找不到返回 null
int? zoneOfTid(int? tid) {
  if (tid == null) return null;
  for (final zone in videoZones) {
    if (zone.tid == tid || zone.children.contains(tid)) {
      return zone.tid;
    }
  }
  return null;
}
