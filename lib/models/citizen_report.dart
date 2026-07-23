import 'package:flutter/material.dart';

import '../design_system.dart';
import 'info_fragment.dart';

enum ReportCategory { rescue, medical, water, food, shelter, road }

extension ReportCategoryPresentation on ReportCategory {
  String get label => switch (this) {
    ReportCategory.rescue => '需要救援',
    ReportCategory.medical => '医疗紧急',
    ReportCategory.water => '缺少饮水',
    ReportCategory.food => '缺少食物',
    ReportCategory.shelter => '需要避难',
    ReportCategory.road => '上报道路',
  };

  String get pageTitle => switch (this) {
    ReportCategory.rescue => '上报救援需求',
    ReportCategory.medical => '上报医疗情况',
    ReportCategory.water => '上报饮水需求',
    ReportCategory.food => '上报食物需求',
    ReportCategory.shelter => '上报避难需求',
    ReportCategory.road => '上报道路情况',
  };

  String get prompt => switch (this) {
    ReportCategory.rescue => '请说明被困人数、现场危险和最需要的帮助',
    ReportCategory.medical => '请说明伤情、人数以及当前需要的医疗物资',
    ReportCategory.water => '请说明缺水人数、可维持时间和附近取水情况',
    ReportCategory.food => '请说明缺少食物的人数和大约可维持时间',
    ReportCategory.shelter => '请说明需要安置的人数和当前位置是否安全',
    ReportCategory.road => '请说明道路名称、积水深度以及车辆或行人能否通行',
  };

  Color get color => switch (this) {
    ReportCategory.rescue || ReportCategory.medical => MosaicColors.red,
    ReportCategory.water || ReportCategory.road => MosaicColors.blue,
    ReportCategory.food => MosaicColors.amber,
    ReportCategory.shelter => MosaicColors.purple,
  };

  FragmentShape get shape => switch (this) {
    ReportCategory.rescue => FragmentShape.circle,
    ReportCategory.medical => FragmentShape.cross,
    ReportCategory.water || ReportCategory.food => FragmentShape.triangle,
    ReportCategory.shelter => FragmentShape.diamond,
    ReportCategory.road => FragmentShape.bar,
  };

  IconData get icon => switch (this) {
    ReportCategory.rescue => Icons.sos_rounded,
    ReportCategory.medical => Icons.local_hospital_rounded,
    ReportCategory.water => Icons.water_drop_rounded,
    ReportCategory.food => Icons.rice_bowl_rounded,
    ReportCategory.shelter => Icons.home_rounded,
    ReportCategory.road => Icons.add_road_rounded,
  };
}

@immutable
class CitizenReport {
  const CitizenReport({
    required this.id,
    required this.category,
    required this.content,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.isUpdated,
    required this.isUrgent,
    this.isDirectedAnswer = false,
  });

  final String id;
  final ReportCategory category;
  final String content;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isUpdated;
  final bool isUrgent;
  final bool isDirectedAnswer;

  CitizenReport copyWith({
    String? content,
    String? location,
    DateTime? updatedAt,
    bool? isUpdated,
    bool? isUrgent,
  }) {
    return CitizenReport(
      id: id,
      category: category,
      content: content ?? this.content,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUpdated: isUpdated ?? this.isUpdated,
      isUrgent: isUrgent ?? this.isUrgent,
      isDirectedAnswer: isDirectedAnswer,
    );
  }

  String get timeLabel {
    final hour = updatedAt.hour.toString().padLeft(2, '0');
    final minute = updatedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get fragmentDescription {
    final prefix = isUpdated ? '已更新 · ' : '';
    return '$prefix$location · $content';
  }
}
