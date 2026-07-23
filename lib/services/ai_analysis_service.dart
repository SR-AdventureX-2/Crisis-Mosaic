import '../models/citizen_report.dart';

class AiReportSuggestion {
  const AiReportSuggestion({
    required this.refinedContent,
    required this.riskHint,
    required this.suggestUrgent,
  });

  final String refinedContent;
  final String riskHint;
  final bool suggestUrgent;
}

class AiCommandBrief {
  const AiCommandBrief({
    required this.headline,
    required this.summary,
    required this.recommendations,
    required this.confidence,
  });

  final String headline;
  final String summary;
  final List<String> recommendations;
  final int confidence;
}

abstract interface class AiAnalysisService {
  Future<AiReportSuggestion> refineReport({
    required ReportCategory category,
    required String content,
    required String location,
  });

  Future<AiCommandBrief> buildCommandBrief({
    required List<CitizenReport> reports,
    required bool hasConflict,
    required bool hasBlindSpot,
  });
}

class LocalAiAnalysisService implements AiAnalysisService {
  const LocalAiAnalysisService();

  static const _urgentKeywords = [
    '被困',
    '受伤',
    '失血',
    '昏迷',
    '老人',
    '儿童',
    '断电',
    '坍塌',
    '无法通行',
    '完全中断',
    '急需',
  ];

  @override
  Future<AiReportSuggestion> refineReport({
    required ReportCategory category,
    required String content,
    required String location,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final normalized = content
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[。！!？?]+$'), '');
    final suggestUrgent = _urgentKeywords.any(normalized.contains);
    final observation = normalized.endsWith('。') ? normalized : '$normalized。';
    final refined =
        '【${category.label}】$observation\n'
        '【位置】$location\n'
        '【建议】${_actionSuggestion(category, suggestUrgent)}';

    return AiReportSuggestion(
      refinedContent: refined,
      riskHint: suggestUrgent
          ? '检测到高风险关键词，建议勾选“情况紧急”并尽快提交。'
          : '已保留原始事实，只调整表达结构；请确认内容无误后提交。',
      suggestUrgent: suggestUrgent,
    );
  }

  @override
  Future<AiCommandBrief> buildCommandBrief({
    required List<CitizenReport> reports,
    required bool hasConflict,
    required bool hasBlindSpot,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 720));
    final urgentCount = reports.where((report) => report.isUrgent).length;
    final updatedCount = reports.where((report) => report.isUpdated).length;
    final risks = <String>[
      if (hasConflict) '沿江路存在时序冲突，建议以最新观察为准并安排复核',
      if (hasBlindSpot) '大关桥仍是关键盲区，影响 3 条救援路线',
      if (urgentCount > 0) '收到 $urgentCount 条居民紧急上报，应优先核验',
      if (updatedCount > 0) '$updatedCount 条信息已更新，旧版本不应继续用于调度',
    ];
    if (risks.isEmpty) {
      risks.add('当前关键冲突与盲区已处理，可继续监控水位变化');
    }

    final confidence =
        (86 -
                (hasConflict ? 14 : 0) -
                (hasBlindSpot ? 18 : 0) +
                (reports.length * 2))
            .clamp(35, 94);
    return AiCommandBrief(
      headline: hasBlindSpot || hasConflict ? '仍有关键决策风险' : '态势趋于清晰',
      summary:
          'AI 已综合 ${27 + reports.length} 条信息碎片、位置、更新时间与紧急标记，识别出 ${risks.length} 个需要关注的行动点。',
      recommendations: risks,
      confidence: confidence,
    );
  }

  String _actionSuggestion(ReportCategory category, bool urgent) {
    if (urgent) {
      return '立即核验位置并通知附近救援力量。';
    }
    return switch (category) {
      ReportCategory.rescue => '补充被困人数及可接近方向。',
      ReportCategory.medical => '补充伤情人数和所需医疗物资。',
      ReportCategory.water => '确认需求人数与附近可用水源。',
      ReportCategory.food => '确认需求人数与可维持时长。',
      ReportCategory.shelter => '确认安置人数及当前位置安全性。',
      ReportCategory.road => '确认车辆、行人通行条件与积水变化。',
    };
  }
}

const aiAnalysisService = LocalAiAnalysisService();
