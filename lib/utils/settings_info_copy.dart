import '../l10n/localized.dart';
import 'app_info.dart';

/// 设置 · 关于 Echo / 数据与隐私 文案。
abstract final class SettingsInfoCopy {
  static String get aboutSubtitle =>
      tr('个人日记与记录', 'Personal journal & notes');

  static String get aboutIntro => tr(
        'Echo 用于记录文字、心情与照片，数据默认保存在本机。'
            '名称取自「回响」：过去的记录可在日后回看。',
        'Echo is for words, mood, and photos — stored on your device by default. '
            'The name means echoes: past entries you can revisit later.',
      );

  static String get aboutPhilosophyTitle =>
      tr('设计原则', 'Design principles');
  static String get aboutPhilosophy => tr(
        '无社交功能，不公开内容，不强制每日打卡。'
            '是否记录、记录多少，由你自行决定。',
        'No social feed, no public sharing, no streak pressure. '
            'What and how much you record is entirely up to you.',
      );

  static String get aboutFeaturesTitle => tr('主要功能', 'Features');
  static List<String> get aboutFeatures => trList(
        [
          '回响：日记正文、图片、天气与心情',
          '漂流瓶：随机打开一篇历史记录',
          '心情之书：按年份与心情浏览',
          '照片墙：按周 / 月展示照片，可导出图片',
          '回响之树：记录进度与收集玩法',
          '待办：提醒与重复',
          '给未来的信：指定日期送达，本地通知',
          '重要日：生日、纪念日提醒',
          '统计：心情流转与阴晴圆缺',
        ],
        [
          'Echoes: text, photos, weather & mood',
          'Drift bottle: open a random past entry',
          'Mood books: browse by year and mood',
          'Photo wall: weekly / monthly grids, export',
          'Echo tree: growth & collectibles',
          'Tasks: reminders & repeats',
          'Letters to the future: deliver on a date',
          'Important days: birthdays & anniversaries',
          'Stats: mood trends over time',
        ],
      );

  static String get aboutAiTitle => tr('摘要如何生成', 'How summaries work');
  static String get aboutAi => tr(
        '关键词与摘要在设备端用本地规则生成，'
            '不调用外部大模型，不上传正文到云端。'
            '精度有限，但内容始终留在你的设备上。',
        'Keywords and summaries are generated on-device with local rules — '
            'no external AI, no uploading your text. '
            'Accuracy is limited, but your words stay on your device.',
      );

  static String get aboutClosing => tr(
        '如有问题或建议，欢迎通过应用商店评价反馈。',
        'Questions or feedback? A kind review on the store helps.',
      );

  static String get privacySubtitle =>
      tr('数据保存在本机', 'Data stays on your device');

  static String get privacyPrincipleTitle => tr('本地优先', 'Local-first');
  static String get privacyPrinciple => tr(
        '无需注册账号，默认不上传日记到服务器。'
            '日记、图片、待办、信件、重要日及各项设置，'
            '均存放在应用私有目录，仅本应用可访问。',
        'No account required. Journals are not uploaded by default. '
            'Entries, photos, tasks, letters, important days, and settings '
            'live in the app\'s private storage.',
      );

  static String get privacyStoredTitle => tr('存储内容', 'What we store');
  static List<String> get privacyStored => trList(
        [
          '回响：正文、心情天气、时间、本地关键词与摘要',
          '图片：你选择添加的副本（应用私有目录）',
          '草稿：未完成的写作',
          '待办：内容、状态、提醒与重复规则',
          '给未来的信：正文、日期与开启状态',
          '重要日：名称、日期、备注与提醒',
          '回响之树：进度等本地状态',
          '设置：纸色、照片墙材质等偏好',
        ],
        [
          'Echoes: text, mood, time, local keywords & summaries',
          'Photos: copies you add (private app folder)',
          'Drafts: unfinished writing',
          'Tasks: content, status, reminders & repeats',
          'Future letters: body, date & opened state',
          'Important days: name, date, notes & reminders',
          'Echo tree: local progress',
          'Settings: appearance & photo wall preferences',
        ],
      );

  static String get privacyNotDoTitle => tr('我们不会', 'What we do not do');
  static List<String> get privacyNotDo => trList(
        [
          '出售或出租你的个人数据',
          '将日记用于广告或用户画像',
          '未经你操作批量上传内容',
          '向第三方共享可识别身份的私人记录',
        ],
        [
          'Sell or rent your personal data',
          'Use your journal for ads or profiling',
          'Batch-upload content without your action',
          'Share identifiable private records with third parties',
        ],
      );

  static String get privacyPermissionsTitle =>
      tr('可能使用的权限', 'Permissions we may request');
  static List<String> get privacyPermissions => trList(
        [
          '通知（可选）：待办、未来来信、重要日提醒',
          '相册 / 相机（可选）：添加图片、自定义照片墙；导出到相册需授权',
          '位置（可选）：仅在你为日记点击「添加当前位置」时使用，坐标与地名存于本机',
          '指纹（可选）：仅用于应用锁本地验证，不上传',
          '精确闹钟（可选）：用于待办准时提醒；可在系统设置中关闭',
          '网络：仅用于 Google Play 购买与恢复 Echo Plus',
        ],
        [
          'Notifications (optional): tasks, future letters, important days',
          'Photos / Camera (optional): add images & photo wall; export needs permission',
          'Location (optional): only when you tap “Add current location” on an entry; stored on device',
          'Fingerprint (optional): app lock only, verified on device, never uploaded',
          'Exact alarms (optional): on-time task reminders; can be disabled in system settings',
          'Internet: Google Play purchases & Echo Plus restore only',
        ],
      );

  static String get privacyPurchasesTitle =>
      tr('Echo Plus 与付款', 'Echo Plus & payments');
  static String get privacyPurchases => tr(
        'Echo Plus 可通过 Google Play 月付、年付或一次性买断解锁全部照片墙与信纸皮肤。'
            '付款由 Google 处理；我们不收集或存储你的银行卡信息。'
            '订阅会自动续费，直至你在 Google Play 订阅管理中取消。'
            '买断为一次性付款。购买记录与权益状态保存在本机，'
            '可通过「恢复购买」在新设备上同步（需同一 Google 账号）。'
            '写日记、待办、导出与应用锁不收费。',
        'Echo Plus unlocks all photo wall and stationery skins via Google Play '
            'monthly, yearly, or lifetime purchase. Google processes payment; '
            'we do not collect card details. Subscriptions renew until you cancel '
            'in Google Play. Lifetime is one-time. Purchase state is stored on device '
            'and can be restored with the same Google account. '
            'Writing, tasks, export, and app lock stay free.',
      );

  static String get privacyBackupTitle => tr('备份说明', 'Backups');
  static String get privacyBackup => tr(
        'Echo 默认关闭 Android 系统自动云备份，以降低日记意外同步到云端的风险。'
            '请使用应用内「备份与导出」自行保存重要数据。',
        'Echo disables Android auto cloud backup by default to reduce accidental '
            'journal sync. Use in-app Backup & export for copies you want to keep.',
      );

  static String get privacyAiTitle => tr('摘要与统计', 'Summaries & statistics');
  static String get privacyAi => tr(
        '日记关键词与摘要在设备端用本地规则生成，'
            '不调用外部大模型。'
            '心情统计与待办数据同样只在本地计算，不上传。',
        'Keywords and summaries are generated on-device without external AI. '
            'Mood stats and task insights are computed locally only.',
      );

  static String get privacyDeleteTitle => tr('删除数据', 'Deleting your data');
  static String get privacyDelete => tr(
        '可在应用内逐条删除回响、待办、信件与重要日。'
            '卸载应用会清除本机全部数据（含图片与数据库）。'
            '卸载前请自行备份需要保留的内容。',
        'Delete individual echoes, tasks, letters, and days in the app. '
            'Uninstalling removes all on-device data. Back up anything you need first.',
      );

  static String get privacyUpdateTitle => tr('说明更新', 'Policy updates');
  static String get privacyUpdate => tr(
        '功能变更时可能更新本说明，重要变更会在应用内提示。最近更新：${AppInfo.lastUpdated}。',
        'We may update this policy when features change. Last updated: ${AppInfo.lastUpdated}.',
      );

  // ── 服务条款 ──────────────────────────────────────────────

  static String get termsSubtitle =>
      tr('使用 Echo 的约定', 'Terms for using Echo');

  static String get termsIntro => tr(
        '使用 Echo 即表示你同意本条款。Echo 是个人日记与记录工具，'
            '不提供医疗或心理咨询服务。',
        'By using Echo you agree to these terms. Echo is a personal journal tool — '
            'not medical or mental-health advice.',
      );

  static String get termsUseTitle => tr('你可以', 'What you may do');
  static List<String> get termsUse => trList(
        [
          '在本机记录日记、待办与个人内容',
          '通过 Google Play 购买或恢复 Echo Plus',
          '导出与备份自己的数据',
        ],
        [
          'Keep personal journals and tasks on your device',
          'Purchase or restore Echo Plus through Google Play',
          'Export and back up your own data',
        ],
      );

  static String get termsPlusTitle => tr('Echo Plus', 'Echo Plus');
  static String get termsPlus => tr(
        '月付约 \$1、年付约 \$9.9、永久买断约 \$29.9（以 Google Play 显示价格为准）。'
            'Plus 解锁全部照片墙与信纸皮肤；核心记录功能保持免费。'
            '月付与年付自动续费，可在 Google Play → 订阅 中随时取消。'
            '买断为一次性付款，不可退款规则以 Google Play 政策为准。'
            '换机后使用同一 Google 账号在应用内「恢复购买」。',
        'About \$1/month, \$9.9/year, or \$29.9 lifetime (Play Store price applies). '
            'Plus unlocks all wall & stationery skins; core journaling stays free. '
            'Monthly/yearly renew until cancelled in Google Play → Subscriptions. '
            'Lifetime is one-time; refunds follow Google Play policy. '
            'Restore purchases with the same Google account on a new device.',
      );

  static String get termsLimitTitle => tr('请勿', 'Please do not');
  static List<String> get termsLimit => trList(
        [
          '利用 Echo 存储或传播违法、侵权或骚扰内容',
          '尝试破解、绕过付费或干扰应用正常运行',
        ],
        [
          'Store or spread illegal, infringing, or harassing content',
          'Attempt to bypass payments or disrupt the app',
        ],
      );

  static String get termsLiabilityTitle => tr('免责声明', 'Disclaimer');
  static String get termsLiability => tr(
        'Echo 按「现状」提供。请自行备份重要数据；'
            '因设备丢失、卸载或系统故障导致的数据损失，'
            '在法律允许范围内我们不承担责任。',
        'Echo is provided “as is.” Back up important data yourself. '
            'We are not liable for loss from device loss, uninstall, or system failure '
            'to the extent permitted by law.',
      );

  static String get termsChangesTitle => tr('条款变更', 'Changes');
  static String get termsChanges => tr(
        '我们可能更新本条款；重要变更会在应用内说明。'
            '最近更新：${AppInfo.lastUpdated}。',
        'We may update these terms; material changes will be noted in the app. '
            'Last updated: ${AppInfo.lastUpdated}.',
      );
}
