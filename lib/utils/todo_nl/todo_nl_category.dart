import '../../models/todo_category.dart';

/// 分类词库：按权重计分，取得分最高类。
abstract final class TodoNlCategoryResolver {
  static TodoCategory resolve(String text, {String? contentHint}) {
    final scores = _scoreText(text);
    if (contentHint != null &&
        contentHint.isNotEmpty &&
        contentHint != text) {
      final hintScores = _scoreText(contentHint);
      for (final entry in hintScores.entries) {
        scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
      }
    }
    return _bestCategory(scores);
  }

  static Map<TodoCategory, int> _scoreText(String text) {
    final scores = {
      for (final category in TodoCategory.values) category: 0,
    };

    for (final entry in _weights.entries) {
      for (final kw in entry.value.entries) {
        if (_matchesKeyword(text, kw.key)) {
          scores[entry.key] = scores[entry.key]! + kw.value;
        }
      }
    }

    return scores;
  }

  static TodoCategory _bestCategory(Map<TodoCategory, int> scores) {
    var best = TodoCategory.life;
    var bestScore = 0;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        best = entry.key;
      }
    }
    return best;
  }

  /// 较长词优先；单字「买」等避免误伤（如「背单词」）。
  static bool _matchesKeyword(String text, String keyword) {
    if (keyword.length >= 2) return text.contains(keyword);

    if (keyword == '买') {
      return RegExp(r'买(?:东西|菜|药|票|个|些|点|了|好|完|单|书|水|奶|肉|菜|药)?').hasMatch(
            text,
          ) ||
          text.startsWith('买') ||
          text.endsWith('买');
    }

    return text.contains(keyword);
  }

  static const _weights = <TodoCategory, Map<String, int>>{
    TodoCategory.work: {
      'ppt': 8,
      'PPT': 8,
      '幻灯片': 8,
      '报告': 8,
      '汇报': 7,
      '文档': 6,
      '方案': 6,
      '开会': 7,
      '会议': 7,
      '周会': 8,
      '例会': 7,
      '复盘': 6,
      '提交': 5,
      'deadline': 7,
      'Deadline': 7,
      '上班': 5,
      '加班': 6,
      '项目': 6,
      '客户': 5,
      '邮件': 5,
      '出差': 6,
      '对接': 5,
      '搞定': 4,
      '交付': 6,
      '演示': 6,
      '提案': 6,
      '表格': 5,
      'excel': 5,
      'Excel': 5,
      '工单': 6,
      '需求': 5,
      '评审': 6,
      '立项': 6,
    },
    TodoCategory.health: {
      '吃药': 9,
      '服药': 9,
      '医院': 8,
      '体检': 8,
      '运动': 7,
      '跑步': 7,
      '健身': 7,
      '晨跑': 8,
      '瑜伽': 7,
      '游泳': 7,
      '打球': 7,
      '锻炼': 6,
      '拉伸': 5,
      '睡觉': 6,
      '早睡': 6,
      '喝水': 6,
      '冥想': 6,
      '挂号': 7,
      '复诊': 7,
      '牙': 5,
      '眼科': 6,
    },
    TodoCategory.social: {
      '打电话': 8,
      '奶奶': 8,
      '爷爷': 8,
      '妈妈': 7,
      '爸爸': 7,
      '朋友': 7,
      '聚会': 7,
      '聚餐': 7,
      '拜访': 6,
      '约会': 6,
      '见面': 5,
      '生日': 7,
      '送礼': 5,
      '探望': 6,
      '聊天': 5,
      '家人': 6,
      '亲戚': 5,
      '外公': 7,
      '外婆': 7,
      '姥姥': 7,
      '姥爷': 7,
      '视频通话': 7,
      '问候': 5,
    },
    TodoCategory.self: {
      '打卡': 10,
      '签到': 9,
      '背单词': 10,
      '背词': 9,
      '抄单词': 10,
      '默写': 9,
      '单词': 8,
      '词汇': 8,
      '背课文': 9,
      '课文': 6,
      '生字': 7,
      '阅读': 7,
      '看书': 7,
      '读书': 7,
      '学习': 8,
      '复习': 7,
      '预习': 7,
      '刷题': 9,
      '做题': 7,
      '题目': 6,
      '练习': 6,
      '上课': 7,
      '听课': 7,
      '网课': 8,
      '课程': 7,
      '考试': 7,
      '期中': 6,
      '期末': 7,
      '考研': 9,
      '考公': 9,
      '考编': 9,
      '雅思': 9,
      '托福': 9,
      '四级': 8,
      '六级': 8,
      '英语': 7,
      '日语': 7,
      '韩语': 7,
      '法语': 7,
      '德语': 7,
      '口语': 7,
      '听力': 7,
      '写作': 6,
      '论文': 7,
      '文献': 6,
      '笔记': 5,
      '编程': 7,
      '代码': 6,
      'leetcode': 8,
      'LeetCode': 8,
      '算法': 7,
      '练琴': 7,
      '画画': 6,
      '练字': 7,
      '素描': 6,
      '古诗': 6,
      '成语': 6,
      '反思': 6,
      '日记': 5,
      '整理房间': 6,
    },
    TodoCategory.life: {
      '房租': 10,
      '交租': 10,
      '还房贷': 9,
      '房贷': 8,
      '信用卡': 7,
      '还款': 7,
      '垃圾': 9,
      '倒垃圾': 10,
      '带下去': 8,
      '超市': 6,
      '买菜': 7,
      '购物': 5,
      '取快递': 7,
      '快递': 6,
      '缴费': 7,
      '打扫': 6,
      '洗衣': 6,
      '做饭': 6,
      '银行': 5,
      '高铁票': 7,
      '机票': 7,
      '火车票': 7,
      '车票': 5,
      '外卖': 5,
      '充值': 5,
      '买东西': 6,
      '购买': 5,
      '采购': 5,
      '交水电': 7,
      '水电费': 7,
      '物业费': 7,
    },
  };

  /// 出现「N号 + 账单类词」时倾向按月重复。
  static bool suggestsMonthly(String text) {
    const billWords = ['房租', '交租', '还房贷', '房贷', '信用卡', '还款', '贷款', '水电', '物业费'];
    if (!RegExp(r'\d{1,2}[号日]').hasMatch(text)) return false;
    return billWords.any(text.contains);
  }
}
