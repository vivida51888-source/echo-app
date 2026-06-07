import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'theme/echo_colors.dart';
import 'pages/main_shell.dart';
import 'services/app_lock_service.dart';
import 'services/diary_draft_service.dart';
import 'services/diary_service.dart';
import 'services/diary_stationery_service.dart';
import 'services/echo_appearance_service.dart';
import 'services/echo_mood_book_service.dart';
import 'services/echo_collectible_service.dart';
import 'services/echo_tree_service.dart';
import 'services/future_letter_notification_service.dart';
import 'services/future_letter_service.dart';
import 'services/important_day_notification_service.dart';
import 'services/important_day_service.dart';
import 'services/locale_service.dart';
import 'services/privacy_service.dart';
import 'services/theme_mode_service.dart';
import 'services/todo_notification_service.dart';
import 'services/photo_wall_settings_service.dart';
import 'services/todo_service.dart';
import 'services/widget_bridge_service.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/echo_splash_gate.dart';
import 'widgets/echo_themed_scope.dart';
import 'widgets/privacy_blur_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DiaryService.instance.init();
  await DiaryDraftService.instance.init();
  await EchoTreeService.instance.init();
  await EchoCollectibleService.instance.init();
  await EchoMoodBookService.instance.init();
  await TodoService.instance.init();
  await ImportantDayService.instance.init();
  await FutureLetterService.instance.init();
  await PhotoWallSettingsService.instance.init();
  await EchoAppearanceService.instance.init();
  await DiaryStationeryService.instance.init();
  await ThemeModeService.instance.init();
  await LocaleService.instance.init();
  await AppLockService.instance.init();
  await PrivacyService.instance.init();
  await WidgetBridgeService.instance.init();
  await TodoNotificationService.instance.initialize();
  await ImportantDayNotificationService.instance.initialize();
  await FutureLetterNotificationService.instance.initialize();
  runApp(const EchoApp());
}

class EchoApp extends StatefulWidget {
  const EchoApp({super.key});

  @override
  State<EchoApp> createState() => _EchoAppState();
}

class _EchoAppState extends State<EchoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    PrivacyService.instance.onLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EchoAppearanceService.instance,
        ThemeModeService.instance,
        LocaleService.instance,
      ]),
      builder: (context, _) {
        final isDark = ThemeModeService.instance.isDark(context);
        EchoColors.setThemeAppearance(isDark: isDark);
        final themeMode = AppTheme.resolveThemeMode(
          ThemeModeService.instance.mode,
        );
        final locale = LocaleService.instance.currentLocale;

        return MaterialApp(
          title: 'Echo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: locale,
          supportedLocales: LocaleService.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const EchoSplashGate(
            child: AppLockGate(child: MainShell()),
          ),
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            return EchoThemedScope(
              child: PrivacyBlurOverlay(
                child: Material(
                  type: MaterialType.transparency,
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
