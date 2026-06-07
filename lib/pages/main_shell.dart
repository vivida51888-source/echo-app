import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/diary.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../services/echo_appearance_service.dart';
import '../services/theme_mode_service.dart';
import '../services/todo_notification_service.dart';
import '../services/todo_service.dart';
import '../theme/echo_colors.dart';
import '../widgets/echo_bottom_nav.dart';
import 'diary_list_page.dart';
import 'home_page.dart';
import 'mood_bookshelf_page.dart';
import 'settings_page.dart';
import 'todo_list_page.dart';
import 'write_diary_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _highlightDiaryId;

  bool get _isNightTab => _currentIndex == 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EchoAppearanceService.instance.addListener(_applySystemChrome);
    ThemeModeService.instance.addListener(_applySystemChrome);
    _applySystemChrome();
    TodoNotificationService.instance.setReminderTapHandler(_onTodoReminderTap);
    TodoNotificationService.instance.processLaunchNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    EchoAppearanceService.instance.removeListener(_applySystemChrome);
    ThemeModeService.instance.removeListener(_applySystemChrome);
    TodoNotificationService.instance.setReminderTapHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      TodoService.instance.rolloverIfNeeded();
      TodoService.instance.processAutoSleep();
      DiaryService.instance.purgeExpiredTrash();
    }
  }

  void _onTodoReminderTap(String todoId) {
    final todo = TodoService.instance.getById(todoId);
    if (todo == null) return;
    setState(() => _currentIndex = 2);
    _applySystemChrome();
  }

  void _applySystemChrome() {
    if (!mounted) return;
    final isDark = ThemeModeService.instance.isDark(context);
    final navIcon =
        isDark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: navIcon,
        systemNavigationBarColor: EchoColors.systemNavBarFor(
          isHomeTab: _isNightTab,
        ),
        systemNavigationBarIconBrightness: navIcon,
      ),
    );
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _applySystemChrome();
  }

  void _clearHighlight() {
    if (_highlightDiaryId != null) {
      setState(() => _highlightDiaryId = null);
    }
  }

  Future<void> _openWriteDiary({
    bool fromEmotionalEntry = false,
    Diary? editingDiary,
  }) async {
    final savedId = await Navigator.of(context).push<String>(
      AppPageRoute<String>(
        builder: (_) => WriteDiaryPage(
          fromEmotionalEntry: fromEmotionalEntry,
          editingDiary: editingDiary,
        ),
      ),
    );
    if (savedId != null && mounted) {
      setState(() {
        _currentIndex = 1;
        _highlightDiaryId = savedId;
      });
      _applySystemChrome();
    }
  }

  Future<void> _onReviewPast() async {
    await showMoodBookshelfSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EchoAppearanceService.instance,
        ThemeModeService.instance,
      ]),
      builder: (context, _) {
        final shellBackground = _isNightTab
            ? EchoColors.homeBackground
            : EchoColors.appBackground;

        return Scaffold(
          backgroundColor: shellBackground,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                onWriteToday: () => _openWriteDiary(fromEmotionalEntry: true),
                onViewToday: () {
                  final today = DiaryService.instance.findTodayEntry();
                  if (today != null) {
                    _openWriteDiary(editingDiary: today);
                  } else {
                    _openWriteDiary(fromEmotionalEntry: true);
                  }
                },
                onReviewPast: _onReviewPast,
              ),
              DiaryListPage(
                highlightDiaryId: _highlightDiaryId,
                onHighlightConsumed: _clearHighlight,
                onWrite: () => _openWriteDiary(),
              ),
              TodoListPage(),
              SettingsPage(),
            ],
          ),
          bottomNavigationBar: EchoBottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            isNight: _isNightTab,
          ),
        );
      },
    );
  }
}
