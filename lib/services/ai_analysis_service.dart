import '../models/citizen_report.dart';
import '../models/conflict_analysis.dart';
import 'ai_api_transport.dart';

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

  Future<AiConflictAnalysisResult> analyzeConflict({
    required String conflictId,
    required int conflictRevision,
    required String location,
    required String topic,
    required List<ConflictEvidence> evidence,
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

  @override
  Future<AiConflictAnalysisResult> analyzeConflict({
    required String conflictId,
    required int conflictRevision,
    required String location,
    required String topic,
    required List<ConflictEvidence> evidence,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1350));
    final imageCount = evidence
        .where((item) => item.modality == EvidenceModality.image)
        .length;
    final textCount = evidence.length - imageCount;
    return AiConflictAnalysisResult.fromJson({
      'analysis_id': 'local-$conflictId-r$conflictRevision',
      'suggested_conclusion': '沿江路东段已被积水覆盖，机动车当前不可通行',
      'reasoning_summary':
          '14:24 后的两条文字上报与两张现场图片相互印证；14:00 的“可通行”描述本身未发现伪造迹象，但已被更新证据反驳，属于过时信息。',
      'confidence': 0.86,
      'recommended_evidence_id': 'text-driver-1428',
      'context_summary': {
        'image_count': imageCount,
        'text_count': textCount,
        'digest': '已按地点、观察时间、来源、OCR、图像特征和文件指纹打包完整上下文。',
      },
      'evidence_assessments': [
        {
          'evidence_id': 'text-resident-1400',
          'authenticity_score': 0.93,
          'credibility_score': 0.38,
          'verdict': 'contradicted',
          'reason': '来源和表述未见异常，但观察时间最早，已被后续水位变化和图像证据反驳。',
          'extracted_facts': ['14:00', '曾可通行', '积水较浅'],
        },
        {
          'evidence_id': 'text-community-1424',
          'authenticity_score': 0.88,
          'credibility_score': 0.84,
          'verdict': 'supported',
          'reason': '水位上涨趋势与 14:26、14:29 两张图片中的道路覆盖情况一致。',
          'extracted_facts': ['14:24', '水位上涨', '漫过路缘'],
        },
        {
          'evidence_id': 'image-road-1426',
          'authenticity_score': 0.91,
          'credibility_score': 0.89,
          'verdict': 'supported',
          'reason': '文件指纹完整；OCR 地点与上报位置一致，视觉参照物支持 25～35 厘米积水判断。',
          'extracted_facts': ['车道连续积水', '沿江路东段', '约 25～35 厘米'],
        },
        {
          'evidence_id': 'text-driver-1428',
          'authenticity_score': 0.94,
          'credibility_score': 0.92,
          'verdict': 'supported',
          'reason': '时间最新，且与前后两张图片及社区联络员文字上报形成交叉验证。',
          'extracted_facts': ['14:28', '车辆无法通行', '路面被淹'],
        },
        {
          'evidence_id': 'image-turnaround-1429',
          'authenticity_score': 0.96,
          'credibility_score': 0.94,
          'verdict': 'supported',
          'reason': '文件指纹和时间连续；图像显示全部车道被积水覆盖且车辆正在掉头。',
          'extracted_facts': ['14:29', '车辆掉头', '无可用机动车道'],
        },
      ],
      'warnings': [
        'AI 只提供辅助判断，最终结论仍需指挥人员确认。',
        '真实性高不等于信息仍然有效；14:00 的上报更可能是已经过时，而非恶意虚假。',
      ],
      'engine_label': '本地多模态演示',
      'model_version': 'multimodal-conflict-demo-v1',
      'data_as_of': '14:29',
    }, usedRemoteApi: false);
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

class ConfigurableAiAnalysisService implements AiAnalysisService {
  const ConfigurableAiAnalysisService({
    required this.localService,
    this.apiBaseUrl = '',
    this.apiToken = '',
  });

  final LocalAiAnalysisService localService;
  final String apiBaseUrl;
  final String apiToken;

  bool get usesRemoteConflictApi => apiBaseUrl.trim().isNotEmpty;

  @override
  Future<AiReportSuggestion> refineReport({
    required ReportCategory category,
    required String content,
    required String location,
  }) {
    return localService.refineReport(
      category: category,
      content: content,
      location: location,
    );
  }

  @override
  Future<AiCommandBrief> buildCommandBrief({
    required List<CitizenReport> reports,
    required bool hasConflict,
    required bool hasBlindSpot,
  }) {
    return localService.buildCommandBrief(
      reports: reports,
      hasConflict: hasConflict,
      hasBlindSpot: hasBlindSpot,
    );
  }

  @override
  Future<AiConflictAnalysisResult> analyzeConflict({
    required String conflictId,
    required int conflictRevision,
    required String location,
    required String topic,
    required List<ConflictEvidence> evidence,
  }) async {
    if (!usesRemoteConflictApi) {
      return localService.analyzeConflict(
        conflictId: conflictId,
        conflictRevision: conflictRevision,
        location: location,
        topic: topic,
        evidence: evidence,
      );
    }

    final normalizedBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final uri = Uri.parse(
      '$normalizedBaseUrl/api/v1/conflicts/$conflictId/ai-analysis',
    );
    final payload = <String, Object?>{
      'incident_id': 'demo-hangzhou-flood',
      'conflict_revision': conflictRevision,
      'context': {
        'location': location,
        'topic': topic,
        'evidence': evidence.map((item) => item.toJson()).toList(),
        'processing': {
          'read_original_text': true,
          'read_images': true,
          'extract_ocr': true,
          'verify_file_hash': true,
          'cross_validate_timeline': true,
        },
      },
    };

    try {
      final response = await postJsonToAiApi(
        uri,
        payload,
        bearerToken: apiToken.isEmpty ? null : apiToken,
      );
      final responseData = response['data'];
      final result = responseData is Map
          ? responseData.cast<String, dynamic>()
          : response;
      return AiConflictAnalysisResult.fromJson(result, usedRemoteApi: true);
    } on Object catch (error) {
      throw AiAnalysisException('多模态 AI API 调用失败，请检查后端连接后重试。', cause: error);
    }
  }
}

class AiAnalysisException implements Exception {
  const AiAnalysisException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

const aiAnalysisService = ConfigurableAiAnalysisService(
  localService: LocalAiAnalysisService(),
  apiBaseUrl: String.fromEnvironment('CRISIS_MOSAIC_API_BASE_URL'),
  apiToken: String.fromEnvironment('CRISIS_MOSAIC_API_TOKEN'),
);
