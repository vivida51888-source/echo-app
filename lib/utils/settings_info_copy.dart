import 'app_info.dart';

/// 设置 · 关于 Echo / 数据与隐私 文案。
abstract final class SettingsInfoCopy {
  // ── 关于 Echo ──────────────────────────────────────────────

  static const aboutSubtitle = '个人日记与记录';

  static const aboutIntro =
      'Echo 用于记录文字、心情与照片，数据默认保存在本机。'
      '名称取自「回响」：过去的记录可在日后回看。';

  static const aboutPhilosophyTitle = '设计原则';
  static const aboutPhilosophy =
      '无社交功能，不公开内容，不强制每日打卡。'
      '是否记录、记录多少，由你自行决定。';

  static const aboutFeaturesTitle = '主要功能';
  static const aboutFeatures = [
    '回响：日记正文、图片、天气与心情',
    '漂流瓶：随机打开一篇历史记录',
    '心情之书：按年份与心情浏览',
    '照片墙：按周 / 月展示照片，可导出图片',
    '回响之树：记录进度与收集玩法',
    '待办：提醒与重复',
    '给未来的信：指定日期送达，本地通知',
    '重要日：生日、纪念日提醒',
    '统计：心情流转与阴晴圆缺',
  ];

  static const aboutAiTitle = '摘要如何生成';
  static const aboutAi =
      '关键词与摘要在设备端用本地规则生成，'
      '不调用外部大模型，不上传正文到云端。'
      '精度有限，但内容始终留在你的设备上。';

  static const aboutClosing =
      '如有问题或建议，欢迎通过应用商店评价反馈。';

  // ── 数据与隐私 ────────────────────────────────────────────

  static const privacySubtitle = '数据保存在本机';

  static const privacyPrincipleTitle = '本地优先';
  static const privacyPrinciple =
      '无需注册账号，默认不上传日记到服务器。'
      '日记、图片、待办、信件、重要日及各项设置，'
      '均存放在应用私有目录，仅本应用可访问。';

  static const privacyStoredTitle = '存储内容';
  static const privacyStored = [
    '回响：正文、心情天气、时间、本地关键词与摘要',
    '图片：你选择添加的副本（应用私有目录）',
    '草稿：未完成的写作',
    '待办：内容、状态、提醒与重复规则',
    '给未来的信：正文、日期与开启状态',
    '重要日：名称、日期、备注与提醒',
    '回响之树：进度等本地状态',
    '设置：纸色、照片墙材质等偏好',
  ];

  static const privacyNotDoTitle = '我们不会';
  static const privacyNotDo = [
    '出售或出租你的个人数据',
    '将日记用于广告或用户画像',
    '未经你操作批量上传内容',
    '向第三方共享可识别身份的私人记录',
  ];

  static const privacyPermissionsTitle = '可能使用的权限';
  static const privacyPermissions = [
    '通知（可选）：待办、未来来信、重要日提醒',
    '相册 / 相机（可选）：添加图片、自定义照片墙；导出图片到相册需授权',
    '时区：在本地正确触发提醒',
  ];

  static const privacyAiTitle = '摘要与统计';
  static const privacyAi =
      '日记关键词与摘要在设备端用本地规则生成，'
      '不调用外部大模型。'
      '心情统计与待办数据同样只在本地计算，不上传。';

  static const privacyDeleteTitle = '删除数据';
  static const privacyDelete =
      '可在应用内逐条删除回响、待办、信件与重要日。'
      '卸载应用会清除本机全部数据（含图片与数据库）。'
      '卸载前请自行备份需要保留的内容。';

  static const privacyUpdateTitle = '说明更新';
  static const privacyUpdate =
      '功能变更时可能更新本说明，重要变更会在应用内提示。'
      '最近更新：${AppInfo.lastUpdated}。';
}

