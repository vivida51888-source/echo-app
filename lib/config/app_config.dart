/// 上架配置：与 [android/app/build.gradle.kts] 的 applicationId 保持一致。
abstract final class AppConfig {
  static const androidApplicationId = 'com.vivida8.echo';

  /// 隐私政策公网地址（Play Console 必填）。
  /// GitHub Pages 部署 docs/privacy.html 后填入，例如：
  /// https://你的用户名.github.io/仓库名/privacy.html
  static const privacyPolicyUrl =
      'https://vivida51888-source.github.io/echo-app/privacy.html';

  /// 服务条款公网地址（可选；应用内已有完整条款页）。
  static const termsOfServiceUrl = '';

  static const supportEmail = 'vivida51888@gmail.com';
}
