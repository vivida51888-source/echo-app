import '../utils/echo_summary_copy.dart';

/// 模拟 AI：规则提取关键词与温柔总结，不接 OpenAI。
class MockAiService {
  MockAiService._();

  static final MockAiService instance = MockAiService._();

  static const _keywordRules = <String, List<String>>{
    '工作': ['工作', '加班', '项目', '会议', '老板', '同事', '职场', '上班'],
    '朋友': ['朋友', '聚会', '聊天', '约', '见面', '老友'],
    '家人': ['妈妈', '爸爸', '父母', '家人', '家', '回家'],
    '熬夜': ['熬夜', '失眠', '很晚', '睡不着', '凌晨'],
    '下雨': ['下雨', '雨', '阴天', '潮湿'],
    '疲惫': ['累', '疲惫', '疲倦', '乏力', '困'],
    '温柔': ['温柔', '温暖', '感动', '治愈', '柔软'],
    '孤独': ['孤独', '孤单', '一个人', '寂寞'],
    '开心': ['开心', '高兴', '快乐', '笑', '愉快'],
    '运动': ['跑步', '健身', '散步', '运动', '走路'],
    '学习': ['学习', '读书', '考试', '课程'],
  };

  List<String> extractKeywords(String content) {
    if (content.trim().isEmpty) return [];

    final found = <String>[];
    for (final entry in _keywordRules.entries) {
      for (final word in entry.value) {
        if (content.contains(word)) {
          found.add(entry.key);
          break;
        }
      }
    }
    return found.take(6).toList();
  }

  /// 形态分档：0 仅图 / 1 空白 / 2 极短 / 3 短 / 4 中 / 5 长。
  int contentTier(String content, {required bool hasImages}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return hasImages ? 0 : 1;
    }
    final len = trimmed.length;
    if (len <= 15) return 2;
    if (len <= 40) return 3;
    if (len <= 120) return 4;
    return 5;
  }

  String generateSummary(
    String content,
    List<String> keywords, {
    String? seed,
    bool hasImages = false,
  }) {
    final stableSeed = seed ?? content.hashCode.toString();
    final tier = contentTier(content, hasImages: hasImages);

    switch (tier) {
      case 0:
        return EchoSummaryCopy.pick(EchoSummaryCopy.imageOnly, stableSeed);
      case 1:
        return EchoSummaryCopy.pick(EchoSummaryCopy.blank, stableSeed);
      case 2:
        return EchoSummaryCopy.pick(EchoSummaryCopy.ultraShort, stableSeed);
      default:
        if (keywords.isNotEmpty) {
          final pool = EchoSummaryCopy.keywordPool(keywords.first);
          if (pool != null) {
            return EchoSummaryCopy.pick(pool, stableSeed);
          }
        }
        return EchoSummaryCopy.pick(
          EchoSummaryCopy.generalForTier(tier),
          stableSeed,
        );
    }
  }

  ({List<String> keywords, String summary}) analyze(
    String content, {
    String? seed,
    bool hasImages = false,
  }) {
    final keywords = extractKeywords(content);
    final summary = generateSummary(
      content,
      keywords,
      seed: seed,
      hasImages: hasImages,
    );
    return (keywords: keywords, summary: summary);
  }
}
