import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../l10n/localized.dart';
import '../models/echo_plus_catalog.dart';

/// Google Play 订阅与买断（Echo Plus）状态与购买流程。
class EchoPlusService extends ChangeNotifier {
  EchoPlusService._();

  static final EchoPlusService instance = EchoPlusService._();

  static const _boxName = 'echo_plus';
  static const _subscriptionActiveKey = 'subscription_active';
  static const _lifetimeKey = 'lifetime';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Box<dynamic>? _box;

  bool _storeAvailable = false;
  bool _loadingProducts = false;
  bool _purchaseInFlight = false;
  String? _lastError;
  List<ProductDetails> _products = [];

  bool get storeAvailable => _storeAvailable;
  bool get loadingProducts => _loadingProducts;
  bool get purchaseInFlight => _purchaseInFlight;
  String? get lastError => _lastError;
  List<ProductDetails> get products => List.unmodifiable(_products);

  bool get hasLifetime => _box?.get(_lifetimeKey) == true;

  bool get hasActiveSubscription =>
      _box?.get(_subscriptionActiveKey) == true;

  bool get isActive => hasLifetime || hasActiveSubscription;

  ProductDetails? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  ProductDetails? get monthlyProduct =>
      productById(EchoPlusCatalog.monthlyId);

  ProductDetails? get yearlyProduct => productById(EchoPlusCatalog.yearlyId);

  ProductDetails? get lifetimeProduct =>
      productById(EchoPlusCatalog.lifetimeId);

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    await _migrateLegacyEntitlement();
    _purchaseSub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e, StackTrace st) {
        debugPrint('Echo Plus purchase stream: $e\n$st');
      },
    );

    _storeAvailable = await _iap.isAvailable();
    if (_storeAvailable) {
      await _loadProducts();
      await refreshEntitlement();
    }
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    _loadingProducts = true;
    _lastError = null;
    notifyListeners();
    try {
      final response =
          await _iap.queryProductDetails(EchoPlusCatalog.productIds);
      if (response.error != null) {
        _lastError = response.error!.message;
        _products = [];
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Echo Plus: products not found: ${response.notFoundIDs}');
      }
      _products = response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } finally {
      _loadingProducts = false;
      notifyListeners();
    }
  }

  /// 从 Play 同步订阅与买断权益。
  Future<void> refreshEntitlement() async {
    if (!_storeAvailable) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();

      var lifetime = false;
      var subscription = false;
      for (final purchase in response.pastPurchases) {
        if (!_isValidPurchase(purchase)) continue;
        if (purchase.productID == EchoPlusCatalog.lifetimeId) {
          lifetime = true;
        } else if (EchoPlusCatalog.subscriptionIds
            .contains(purchase.productID)) {
          subscription = true;
        }
      }
      await _setLifetime(lifetime);
      await _setSubscriptionActive(subscription);
    } else {
      await _iap.restorePurchases();
    }
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    if (_purchaseInFlight || !_storeAvailable) return;
    _purchaseInFlight = true;
    _lastError = null;
    notifyListeners();
    try {
      final ok = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!ok) {
        _lastError = tr('无法发起购买', 'Could not start purchase');
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _purchaseInFlight = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) return;
    _lastError = null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await refreshEntitlement();
    } else {
      await _iap.restorePurchases();
    }
    notifyListeners();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!EchoPlusCatalog.productIds.contains(purchase.productID)) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == EchoPlusCatalog.lifetimeId) {
            await _setLifetime(true);
          } else {
            await _setSubscriptionActive(true);
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          _lastError =
              purchase.error?.message ?? tr('购买失败', 'Purchase failed');
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
    notifyListeners();
  }

  bool _isValidPurchase(PurchaseDetails purchase) {
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  Future<void> _setLifetime(bool value) async {
    final current = _box?.get(_lifetimeKey) == true;
    await _box?.put(_lifetimeKey, value);
    if (current != value) notifyListeners();
  }

  Future<void> _setSubscriptionActive(bool value) async {
    final current = _box?.get(_subscriptionActiveKey) == true;
    await _box?.put(_subscriptionActiveKey, value);
    if (current != value) notifyListeners();
  }

  Future<void> _migrateLegacyEntitlement() async {
    const legacyKey = 'active';
    if (_box?.get(legacyKey) == true &&
        _box?.get(_subscriptionActiveKey) != true) {
      await _box?.put(_subscriptionActiveKey, true);
      await _box?.delete(legacyKey);
    }
  }

  @visibleForTesting
  Future<void> setActiveForTest({bool lifetime = false, bool subscription = false}) async {
    await _setLifetime(lifetime);
    await _setSubscriptionActive(subscription);
  }
}
