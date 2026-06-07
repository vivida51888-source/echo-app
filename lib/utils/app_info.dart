/// 应用版本信息（与 pubspec.yaml 保持一致）。
abstract final class AppInfo {
  static const name = 'Echo';
  static const tagline = '安静地记录，未来为你回响';
  static const version = '1.0.0';
  static const build = '1';
  static const lastUpdated = '2026 年 5 月';

  static String get versionLabel => 'v$version ($build)';
}
