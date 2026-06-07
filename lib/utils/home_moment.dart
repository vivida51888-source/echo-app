import '../models/diary.dart';
import '../services/diary_draft_service.dart';
import '../services/diary_service.dart';

/// 此刻首页主行动区状态。
enum HomeMomentAction {
  /// 今日尚无记录与草稿。
  writeToday,

  /// 有未保存草稿（含今日已保存后又继续写）。
  continueToday,

  /// 今日日记已保存且无草稿。
  showQuote,
}

abstract final class HomeMoment {
  static HomeMomentAction resolve({
    required Diary? todayEntry,
    required bool hasTodayDraft,
  }) {
    if (hasTodayDraft) return HomeMomentAction.continueToday;
    if (todayEntry != null) return HomeMomentAction.showQuote;
    return HomeMomentAction.writeToday;
  }

  static ({
    HomeMomentAction action,
    Diary? todayEntry,
    bool hasTodayDraft,
  }) snapshot() {
    final todayEntry = DiaryService.instance.findTodayEntry();
    final hasTodayDraft = DiaryDraftService.instance.hasTodayDraft;
    return (
      action: resolve(
        todayEntry: todayEntry,
        hasTodayDraft: hasTodayDraft,
      ),
      todayEntry: todayEntry,
      hasTodayDraft: hasTodayDraft,
    );
  }
}
