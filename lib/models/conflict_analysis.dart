enum EvidenceModality { text, image }

enum EvidenceVerdict { supported, likely, uncertain, contradicted }

extension EvidenceModalityPresentation on EvidenceModality {
  String get label => switch (this) {
    EvidenceModality.text => '文字',
    EvidenceModality.image => '图片',
  };
}

extension EvidenceVerdictPresentation on EvidenceVerdict {
  String get label => switch (this) {
    EvidenceVerdict.supported => '相互印证',
    EvidenceVerdict.likely => '较可信',
    EvidenceVerdict.uncertain => '待核验',
    EvidenceVerdict.contradicted => '已被新证据反驳',
  };
}

class ConflictEvidence {
  const ConflictEvidence({
    required this.id,
    required this.modality,
    required this.source,
    required this.observedAt,
    required this.statement,
    required this.location,
    this.fileName,
    this.imageUrl,
    this.ocrText,
    this.visualFindings,
    this.contentSha256,
  });

  final String id;
  final EvidenceModality modality;
  final String source;
  final String observedAt;
  final String statement;
  final String location;
  final String? fileName;
  final String? imageUrl;
  final String? ocrText;
  final String? visualFindings;
  final String? contentSha256;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'modality': modality.name,
      'source': source,
      'observed_at': observedAt,
      'statement': statement,
      'location': location,
      if (fileName != null) 'file_name': fileName,
      if (imageUrl != null) 'image_url': imageUrl,
      if (ocrText != null) 'ocr_text': ocrText,
      if (visualFindings != null) 'visual_findings': visualFindings,
      if (contentSha256 != null) 'content_sha256': contentSha256,
    };
  }
}

class EvidenceCredibilityAssessment {
  const EvidenceCredibilityAssessment({
    required this.evidenceId,
    required this.authenticityScore,
    required this.credibilityScore,
    required this.verdict,
    required this.reason,
    required this.extractedFacts,
  });

  final String evidenceId;
  final int authenticityScore;
  final int credibilityScore;
  final EvidenceVerdict verdict;
  final String reason;
  final List<String> extractedFacts;

  factory EvidenceCredibilityAssessment.fromJson(Map<String, dynamic> json) {
    return EvidenceCredibilityAssessment(
      evidenceId: json['evidence_id'] as String? ?? '',
      authenticityScore: _asPercent(json['authenticity_score']),
      credibilityScore: _asPercent(json['credibility_score']),
      verdict: _verdictFromName(json['verdict'] as String?),
      reason: json['reason'] as String? ?? '暂无说明',
      extractedFacts: _stringList(json['extracted_facts']),
    );
  }
}

class AiConflictAnalysisResult {
  const AiConflictAnalysisResult({
    required this.analysisId,
    required this.conclusion,
    required this.reasoningSummary,
    required this.confidence,
    required this.recommendedEvidenceId,
    required this.assessments,
    required this.warnings,
    required this.imageCount,
    required this.textCount,
    required this.contextDigest,
    required this.engineLabel,
    required this.modelVersion,
    required this.dataAsOf,
    required this.usedRemoteApi,
  });

  final String analysisId;
  final String conclusion;
  final String reasoningSummary;
  final int confidence;
  final String recommendedEvidenceId;
  final List<EvidenceCredibilityAssessment> assessments;
  final List<String> warnings;
  final int imageCount;
  final int textCount;
  final String contextDigest;
  final String engineLabel;
  final String modelVersion;
  final String dataAsOf;
  final bool usedRemoteApi;

  factory AiConflictAnalysisResult.fromJson(
    Map<String, dynamic> json, {
    required bool usedRemoteApi,
  }) {
    final context = _map(json['context_summary']);
    final assessmentItems = json['evidence_assessments'];
    return AiConflictAnalysisResult(
      analysisId: json['analysis_id'] as String? ?? 'analysis-unknown',
      conclusion: json['suggested_conclusion'] as String? ?? '当前证据不足，建议人工复核',
      reasoningSummary: json['reasoning_summary'] as String? ?? '未返回分析依据。',
      confidence: _asPercent(json['confidence']),
      recommendedEvidenceId: json['recommended_evidence_id'] as String? ?? '',
      assessments: assessmentItems is List
          ? assessmentItems
                .whereType<Map>()
                .map(
                  (item) => EvidenceCredibilityAssessment.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList(growable: false)
          : const [],
      warnings: _stringList(json['warnings']),
      imageCount: _asInt(context['image_count']),
      textCount: _asInt(context['text_count']),
      contextDigest: context['digest'] as String? ?? '上下文摘要不可用',
      engineLabel: json['engine_label'] as String? ?? '多模态冲突分析 API',
      modelVersion: json['model_version'] as String? ?? 'unknown',
      dataAsOf: json['data_as_of'] as String? ?? '',
      usedRemoteApi: usedRemoteApi,
    );
  }
}

const demoRoadConflictEvidence = <ConflictEvidence>[
  ConflictEvidence(
    id: 'text-resident-1400',
    modality: EvidenceModality.text,
    source: '沿江路居民上报',
    observedAt: '14:00',
    statement: '车辆可正常通行，积水未超过轮胎。',
    location: '沿江路',
  ),
  ConflictEvidence(
    id: 'text-community-1424',
    modality: EvidenceModality.text,
    source: 'A 社区联络员',
    observedAt: '14:24',
    statement: '水位快速上涨，已经漫过道路边缘。',
    location: '沿江路东段',
  ),
  ConflictEvidence(
    id: 'image-road-1426',
    modality: EvidenceModality.image,
    source: '现场居民图片',
    observedAt: '14:26',
    statement: '沿江路车道积水现场图。',
    location: '沿江路东段',
    fileName: 'IMG_1426_沿江路.jpg',
    imageUrl: 'demo://evidence/along-river-road-1426.jpg',
    ocrText: '沿江路 东向西',
    visualFindings: '车道被连续积水覆盖，以路缘和护栏为参照估算水深约 25～35 厘米。',
    contentSha256: 'demo-sha256-road-1426',
  ),
  ConflictEvidence(
    id: 'text-driver-1428',
    modality: EvidenceModality.text,
    source: '网约车司机上报',
    observedAt: '14:28',
    statement: '路面已被淹，车辆无法继续通行。',
    location: '沿江路东段',
  ),
  ConflictEvidence(
    id: 'image-turnaround-1429',
    modality: EvidenceModality.image,
    source: '巡查人员图片',
    observedAt: '14:29',
    statement: '车辆在积水路段前掉头。',
    location: '沿江路东段',
    fileName: 'IMG_1429_车辆受阻.jpg',
    imageUrl: 'demo://evidence/along-river-road-1429.jpg',
    ocrText: '前方积水 注意绕行',
    visualFindings: '积水横跨全部车道，两辆车辆在警示牌前掉头，未发现可用机动车通道。',
    contentSha256: 'demo-sha256-road-1429',
  ),
];

EvidenceVerdict _verdictFromName(String? value) {
  return EvidenceVerdict.values.firstWhere(
    (item) => item.name == value,
    orElse: () => EvidenceVerdict.uncertain,
  );
}

Map<String, dynamic> _map(Object? value) {
  return value is Map ? value.cast<String, dynamic>() : const {};
}

List<String> _stringList(Object? value) {
  return value is List
      ? value.whereType<Object>().map((item) => item.toString()).toList()
      : const [];
}

int _asInt(Object? value) {
  return switch (value) {
    int number => number,
    double number => number.round(),
    String text => int.tryParse(text) ?? 0,
    _ => 0,
  };
}

int _asPercent(Object? value) {
  final number = switch (value) {
    int number => number.toDouble(),
    double number => number,
    String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
  final percentage = number <= 1 ? number * 100 : number;
  return percentage.round().clamp(0, 100);
}
