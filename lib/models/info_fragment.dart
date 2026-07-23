import 'package:flutter/material.dart';

import '../design_system.dart';

enum FragmentShape { circle, triangle, cross, bar, diamond, hole }

enum FragmentStatus { normal, conflict, blind }

@immutable
class InfoFragment {
  const InfoFragment({
    required this.id,
    required this.shape,
    required this.label,
    required this.description,
    required this.color,
    required this.status,
    required this.time,
  });

  final int id;
  final FragmentShape shape;
  final String label;
  final String description;
  final Color color;
  final FragmentStatus status;
  final String time;

  InfoFragment copyWith({
    String? description,
    Color? color,
    FragmentStatus? status,
  }) {
    return InfoFragment(
      id: id,
      shape: shape,
      label: label,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      time: time,
    );
  }
}

const demoFragments = <InfoFragment>[
  InfoFragment(
    id: 1,
    shape: FragmentShape.circle,
    label: 'A 社区',
    description: '运河西岸 · 60人被困',
    color: MosaicColors.amber,
    status: FragmentStatus.normal,
    time: '14:10',
  ),
  InfoFragment(
    id: 2,
    shape: FragmentShape.triangle,
    label: 'B 仓库',
    description: '饮用水 200箱',
    color: MosaicColors.green,
    status: FragmentStatus.normal,
    time: '14:15',
  ),
  InfoFragment(
    id: 3,
    shape: FragmentShape.cross,
    label: 'C 医院',
    description: '剩余 12 床位',
    color: MosaicColors.red,
    status: FragmentStatus.normal,
    time: '14:20',
  ),
  InfoFragment(
    id: 4,
    shape: FragmentShape.bar,
    label: '沿江路',
    description: '14:00 车辆可通行（居民）',
    color: MosaicColors.blue,
    status: FragmentStatus.conflict,
    time: '14:00',
  ),
  InfoFragment(
    id: 5,
    shape: FragmentShape.bar,
    label: '沿江路',
    description: '14:28 路面已被淹（司机）',
    color: MosaicColors.blue,
    status: FragmentStatus.conflict,
    time: '14:28',
  ),
  InfoFragment(
    id: 6,
    shape: FragmentShape.diamond,
    label: '文体中心',
    description: '避难所 · 容纳 200人',
    color: MosaicColors.purple,
    status: FragmentStatus.normal,
    time: '14:05',
  ),
  InfoFragment(
    id: 7,
    shape: FragmentShape.hole,
    label: '大关桥',
    description: '通行状态未知 · 影响3条路线',
    color: MosaicColors.hole,
    status: FragmentStatus.blind,
    time: '',
  ),
];
