import '../config/app_config.dart';

/// Google Play 商品 ID（须与 Play Console 完全一致）。
abstract final class EchoPlusCatalog {
  /// 与 [AppConfig.androidApplicationId] / Gradle applicationId 保持一致。
  static const packageName = AppConfig.androidApplicationId;

  /// 订阅：Play Console → 获利 → 订阅
  static const monthlyId = 'echo_plus_monthly';
  static const yearlyId = 'echo_plus_yearly';

  /// 一次性买断：Play Console → 获利 → 应用内商品（非消耗型）
  static const lifetimeId = 'echo_plus_lifetime';

  static const subscriptionIds = <String>{
    monthlyId,
    yearlyId,
  };

  static const productIds = <String>{
    monthlyId,
    yearlyId,
    lifetimeId,
  };

  /// Play Console 定价基准（美元）；界面显示价格以商店返回为准。
  static const monthlyUsd = 1.0;
  static const yearlyUsd = 9.9;
  static const lifetimeUsd = 29.9;
}
