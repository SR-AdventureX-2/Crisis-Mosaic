import 'package:flutter/material.dart';

import '../design_system.dart';
import '../models/citizen_report.dart';
import '../models/conflict_analysis.dart';
import '../models/info_fragment.dart';
import '../services/ai_analysis_service.dart';
import '../widgets/fragment_card.dart';
import '../widgets/map_panel.dart';

enum _PriorityLevel { high, medium, low }

class CommandScreen extends StatefulWidget {
  const CommandScreen({
    super.key,
    required this.citizenReports,
    required this.directedReport,
    required this.conflictAnalyzing,
    required this.conflictAnalysis,
    required this.conflictAnalysisError,
    required this.conflictResolved,
    required this.roadFlooded,
    required this.onAnalyzeConflict,
    required this.onResolveConflict,
  });

  final List<CitizenReport> citizenReports;
  final CitizenReport? directedReport;
  final bool conflictAnalyzing;
  final AiConflictAnalysisResult? conflictAnalysis;
  final String? conflictAnalysisError;
  final bool conflictResolved;
  final bool roadFlooded;
  final VoidCallback onAnalyzeConflict;
  final ValueChanged<bool> onResolveConflict;

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  _PriorityLevel _priority = _PriorityLevel.high;
  AiCommandBrief? _aiBrief;
  bool _aiLoading = false;

  @override
  void didUpdateWidget(covariant CommandScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final informationChanged =
        oldWidget.citizenReports.length != widget.citizenReports.length ||
        oldWidget.conflictResolved != widget.conflictResolved ||
        (oldWidget.directedReport == null) != (widget.directedReport == null);
    if (informationChanged) {
      _aiBrief = null;
    }
  }

  Future<void> _generateAiBrief() async {
    if (_aiLoading) {
      return;
    }
    setState(() => _aiLoading = true);
    final brief = await aiAnalysisService.buildCommandBrief(
      reports: widget.citizenReports,
      hasConflict: !widget.conflictResolved,
      hasBlindSpot: widget.directedReport == null,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _aiBrief = brief;
      _aiLoading = false;
    });
  }

  List<InfoFragment> get _visibleFragments {
    final baseFragments = demoFragments
        .where((fragment) {
          if (widget.directedReport != null && fragment.id == 7) {
            return false;
          }
          if (!widget.conflictResolved) {
            return true;
          }
          if (widget.roadFlooded) {
            return fragment.id != 4;
          }
          return fragment.id != 5;
        })
        .map((fragment) {
          if (widget.conflictResolved &&
              widget.roadFlooded &&
              fragment.id == 5) {
            return fragment.copyWith(
              status: FragmentStatus.normal,
              description: '14:28 路面已被淹（已确认）',
              color: MosaicColors.red,
            );
          }
          if (widget.conflictResolved &&
              !widget.roadFlooded &&
              fragment.id == 4) {
            return fragment.copyWith(
              status: FragmentStatus.normal,
              description: '14:00 车辆可通行（已确认）',
              color: MosaicColors.blue,
            );
          }
          return fragment;
        })
        .toList(growable: false);

    final reportFragments = <InfoFragment>[
      for (var index = 0; index < widget.citizenReports.length; index++)
        InfoFragment(
          id: 1000 + index,
          shape: widget.citizenReports[index].category.shape,
          label: widget.citizenReports[index].location,
          description: widget.citizenReports[index].fragmentDescription,
          color: widget.citizenReports[index].isUrgent
              ? MosaicColors.red
              : widget.citizenReports[index].category.color,
          status: FragmentStatus.normal,
          time: widget.citizenReports[index].timeLabel,
        ),
    ];
    return [...reportFragments, ...baseFragments];
  }

  @override
  Widget build(BuildContext context) {
    final fragments = _visibleFragments;

    return ColoredBox(
      color: MosaicColors.background,
      child: Column(
        children: [
          _StatusBar(
            fragmentCount:
                27 +
                widget.citizenReports.length -
                (widget.conflictResolved ? 1 : 0),
            blindCount: widget.directedReport == null ? 1 : 0,
            conflictCount: widget.conflictResolved ? 0 : 1,
          ),
          Expanded(
            child: RefreshIndicator(
              color: MosaicColors.blue,
              onRefresh: () =>
                  Future<void>.delayed(const Duration(milliseconds: 550)),
              child: ListView(
                key: const PageStorageKey('command-scroll'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: const BoxDecoration(
                      color: MosaicColors.white,
                      boxShadow: MosaicShadow.subtle,
                    ),
                    child: MapPanel(
                      conflictResolved: widget.conflictResolved,
                      blindSpotResolved: widget.directedReport != null,
                      resolvedRoadColor: widget.roadFlooded
                          ? MosaicColors.red
                          : MosaicColors.blue,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PrioritySelector(
                      selected: _priority,
                      highCount:
                          (widget.conflictResolved ? 0 : 1) +
                          (widget.directedReport == null ? 1 : 0) +
                          widget.citizenReports
                              .where((report) => report.isUrgent)
                              .length,
                      onSelected: (value) => setState(() => _priority = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildPriorityContent(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '全量信息碎片',
                            style: TextStyle(
                              color: MosaicColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: withOpacityValue(MosaicColors.lead, 0.05),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            child: Text(
                              '${fragments.length}',
                              style: const TextStyle(
                                color: MosaicColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._buildFragmentCards(fragments),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityContent() {
    switch (_priority) {
      case _PriorityLevel.high:
        return Padding(
          key: const ValueKey('high-priority-content'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            children: [
              _AiCommandBriefCard(
                brief: _aiBrief,
                loading: _aiLoading,
                onGenerate: _generateAiBrief,
              ),
              const SizedBox(height: 16),
              if (!widget.conflictResolved) ...[
                _ConflictDecisionCard(
                  analyzing: widget.conflictAnalyzing,
                  analysis: widget.conflictAnalysis,
                  errorMessage: widget.conflictAnalysisError,
                  evidence: demoRoadConflictEvidence,
                  onAnalyze: widget.onAnalyzeConflict,
                  onAcceptOpen: () => widget.onResolveConflict(false),
                  onAcceptFlooded: () => widget.onResolveConflict(true),
                ),
                const SizedBox(height: 16),
              ],
              _BlindSpotCard(report: widget.directedReport),
              if (widget.citizenReports.any((report) => report.isUrgent)) ...[
                const SizedBox(height: 16),
                _UrgentReportsCard(
                  reports: widget.citizenReports
                      .where((report) => report.isUrgent)
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        );
      case _PriorityLevel.medium:
        final reports = widget.citizenReports
            .where((report) => !report.isUrgent)
            .toList(growable: false);
        if (reports.isEmpty) {
          return const _EmptyPriorityState(
            key: ValueKey('medium-priority-content'),
            label: '当前无中优先级待确认信息',
          );
        }
        return _PriorityReportsCard(
          key: const ValueKey('medium-priority-content'),
          title: '居民最新上报',
          reports: reports,
        );
      case _PriorityLevel.low:
        return const _EmptyPriorityState(
          key: ValueKey('low-priority-content'),
          label: '当前无低优先级待确认信息',
        );
    }
  }

  List<Widget> _buildFragmentCards(List<InfoFragment> fragments) {
    final cards = <Widget>[];
    for (var index = 0; index < fragments.length; index++) {
      final fragment = fragments[index];
      final isConflict = fragment.status == FragmentStatus.conflict;
      final previousWasConflict =
          index > 0 && fragments[index - 1].status == FragmentStatus.conflict;
      if (isConflict && previousWasConflict) {
        continue;
      }

      if (isConflict && index + 1 < fragments.length) {
        cards.add(
          ConflictConnector(
            key: const Key('conflict-fragment-pair'),
            child: Column(
              children: [
                FragmentCard(
                  fragment: fragment,
                  isConflict: true,
                  onTap: () => _showFragmentDetails(fragment),
                ),
                FragmentCard(
                  fragment: fragments[index + 1],
                  isConflict: true,
                  onTap: () => _showFragmentDetails(fragments[index + 1]),
                ),
              ],
            ),
          ),
        );
      } else {
        cards.add(
          FragmentCard(
            fragment: fragment,
            onTap: () => _showFragmentDetails(fragment),
          ),
        );
      }
    }
    return cards;
  }

  void _showFragmentDetails(InfoFragment fragment) {
    CitizenReport? citizenReport;
    if (fragment.id >= 1000) {
      final index = fragment.id - 1000;
      if (index >= 0 && index < widget.citizenReports.length) {
        citizenReport = widget.citizenReports[index];
      }
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: MosaicColors.background,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (context) => _FragmentDetailSheet(
        fragment: fragment,
        citizenReport: citizenReport,
      ),
    );
  }
}

class _AiCommandBriefCard extends StatelessWidget {
  const _AiCommandBriefCard({
    required this.brief,
    required this.loading,
    required this.onGenerate,
  });

  final AiCommandBrief? brief;
  final bool loading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MosaicColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: withOpacityValue(MosaicColors.purple, 0.2)),
          boxShadow: MosaicShadow.tinted(MosaicColors.purple, opacity: 0.07),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: withOpacityValue(MosaicColors.purple, 0.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: MosaicColors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 态势简报',
                        style: TextStyle(
                          color: MosaicColors.lead,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '综合冲突、盲区、时效与居民上报',
                        style: TextStyle(
                          color: MosaicColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('本地智能', foreground: MosaicColors.purple),
              ],
            ),
            if (brief case final value?) ...[
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      value.headline,
                      style: const TextStyle(
                        color: MosaicColors.lead,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: withOpacityValue(MosaicColors.green, 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      child: Text(
                        '置信度 ${value.confidence}%',
                        style: const TextStyle(
                          color: MosaicColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                value.summary,
                style: const TextStyle(
                  color: MosaicColors.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ...value.recommendations.map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 17,
                          color: MosaicColors.amber,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: const TextStyle(
                            color: MosaicColors.lead,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('generate-ai-brief'),
                onPressed: loading ? null : onGenerate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: MosaicColors.purple,
                  backgroundColor: withOpacityValue(MosaicColors.purple, 0.05),
                  side: BorderSide(
                    color: withOpacityValue(MosaicColors.purple, 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MosaicColors.purple,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  loading
                      ? '正在生成研判…'
                      : brief == null
                      ? '生成 AI 态势简报'
                      : '根据最新信息重新生成',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FragmentDetailSheet extends StatelessWidget {
  const _FragmentDetailSheet({
    required this.fragment,
    required this.citizenReport,
  });

  final InfoFragment fragment;
  final CitizenReport? citizenReport;

  @override
  Widget build(BuildContext context) {
    final isConflict = fragment.status == FragmentStatus.conflict;
    final isBlind = fragment.status == FragmentStatus.blind;
    final confidence = isBlind ? 0.18 : (isConflict ? 0.58 : 0.82);
    final accent = isBlind ? MosaicColors.lead : fragment.color;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: withOpacityValue(accent, 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ShapeGlyph(
                  shape: fragment.shape,
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fragment.label,
                      style: const TextStyle(
                        color: MosaicColors.lead,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      citizenReport?.category.label ?? '信息碎片详情',
                      style: const TextStyle(
                        color: MosaicColors.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('close-fragment-detail'),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '关闭',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: MosaicColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: withOpacityValue(MosaicColors.lead, 0.07),
              ),
            ),
            child: Text(
              citizenReport?.content ?? fragment.description,
              style: const TextStyle(
                color: MosaicColors.lead,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: '信息来源',
            value: citizenReport == null ? '模拟观察员' : '匿名居民',
          ),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: citizenReport?.isUpdated == true ? '最后更新' : '观察时间',
            value: fragment.time.isEmpty ? '等待确认' : fragment.time,
          ),
          _DetailRow(
            icon: Icons.timer_outlined,
            label: '信息时效',
            value: isBlind ? '尚未获得' : '约 26 分钟后过期',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '综合置信度',
                style: TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${(confidence * 100).round()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              color: accent,
              backgroundColor: withOpacityValue(accent, 0.1),
            ),
          ),
          if (isConflict) ...[
            const SizedBox(height: 24),
            const Text(
              '冲突时间线',
              style: TextStyle(
                color: MosaicColors.lead,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const _TimelineEntry(time: '14:00', title: '居民观察：车辆可通行'),
            const _TimelineEntry(
              time: '14:28',
              title: '司机观察：路面已被淹',
              highlighted: true,
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: withOpacityValue(MosaicColors.amber, 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text(
                '系统推断：水位正在上涨，建议改道或再次确认。',
                style: TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: MosaicColors.mutedText, size: 19),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: MosaicColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: MosaicColors.lead,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.time,
    required this.title,
    this.highlighted = false,
  });

  final String time;
  final String title;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: highlighted ? MosaicColors.red : MosaicColors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: const TextStyle(
              color: MosaicColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: highlighted ? MosaicColors.red : MosaicColors.lead,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.fragmentCount,
    required this.blindCount,
    required this.conflictCount,
  });

  final int fragmentCount;
  final int blindCount;
  final int conflictCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: MosaicColors.lead,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const ProductMark(size: 24, borderRadius: 7),
            const SizedBox(width: 8),
            const Text(
              '杭州 · 洪灾',
              style: TextStyle(
                color: MosaicColors.background,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeNow(),
              style: TextStyle(
                color: withOpacityValue(MosaicColors.background, 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 24),
            _StatusMetric(label: '碎片', value: fragmentCount),
            const SizedBox(width: 12),
            _StatusMetric(label: '盲区', value: blindCount),
            if (conflictCount > 0) ...[
              const SizedBox(width: 12),
              _StatusMetric(
                label: '冲突',
                value: conflictCount,
                color: MosaicColors.amber,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.label,
    required this.value,
    this.color = MosaicColors.background,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        children: [
          TextSpan(
            text: '$value',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.highCount,
    required this.onSelected,
  });

  final _PriorityLevel selected;
  final int highCount;
  final ValueChanged<_PriorityLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: withOpacityValue(MosaicColors.lead, 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _PriorityLevel.values
            .map((priority) {
              final isSelected = priority == selected;
              final label = switch (priority) {
                _PriorityLevel.high => '高优先级',
                _PriorityLevel.medium => '中优先级',
                _PriorityLevel.low => '低优先级',
              };

              return Expanded(
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('priority-${priority.name}'),
                      onTap: () => onSelected(priority),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MosaicColors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected ? MosaicShadow.subtle : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? MosaicColors.lead
                                    : MosaicColors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (priority == _PriorityLevel.high &&
                                highCount > 0)
                              Positioned(
                                top: 5,
                                right: 4,
                                child: Container(
                                  width: 17,
                                  height: 17,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: MosaicColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$highCount',
                                    style: const TextStyle(
                                      color: MosaicColors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ConflictDecisionCard extends StatelessWidget {
  const _ConflictDecisionCard({
    required this.analyzing,
    required this.analysis,
    required this.errorMessage,
    required this.evidence,
    required this.onAnalyze,
    required this.onAcceptOpen,
    required this.onAcceptFlooded,
  });

  final bool analyzing;
  final AiConflictAnalysisResult? analysis;
  final String? errorMessage;
  final List<ConflictEvidence> evidence;
  final VoidCallback onAnalyze;
  final VoidCallback onAcceptOpen;
  final VoidCallback onAcceptFlooded;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MosaicColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: withOpacityValue(MosaicColors.red, 0.28)),
          boxShadow: MosaicShadow.tinted(MosaicColors.red, opacity: 0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SectionLabel('逻辑冲突', foreground: MosaicColors.red),
                const Spacer(),
                const Text(
                  '14:28 更新',
                  style: TextStyle(
                    color: MosaicColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '沿江路通行状态冲突',
              style: TextStyle(
                color: MosaicColors.lead,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '同一地点收到多条相互矛盾的图文资料。AI 将读取全部证据、构建完整上下文并评估真实性与可信度。',
              style: TextStyle(
                color: MosaicColors.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EvidenceCounter(
                  icon: Icons.image_rounded,
                  label:
                      '${evidence.where((item) => item.modality == EvidenceModality.image).length} 张图片',
                ),
                _EvidenceCounter(
                  icon: Icons.subject_rounded,
                  label:
                      '${evidence.where((item) => item.modality == EvidenceModality.text).length} 条文字',
                ),
                const _EvidenceCounter(
                  icon: Icons.location_on_rounded,
                  label: '同一地点',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analyzing)
              const _ConflictAnalyzingState()
            else if (errorMessage != null)
              _ConflictAnalysisError(message: errorMessage!, onRetry: onAnalyze)
            else if (analysis == null)
              _ConflictAnalyzeButton(onPressed: onAnalyze)
            else ...[
              const Divider(color: MosaicColors.mapLine),
              const SizedBox(height: 12),
              _ConflictAnalysisResultView(
                result: analysis!,
                evidence: evidence,
                onRegenerate: onAnalyze,
              ),
              const SizedBox(height: 16),
              const Text(
                '人工确认最终结论',
                style: TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final first = _AnalysisOption(
                    meta: '14:00 · 居民',
                    value: '车辆可通行',
                    buttonLabel: '采信此条',
                    onPressed: onAcceptOpen,
                  );
                  final second = _AnalysisOption(
                    key: const Key('latest-analysis-option'),
                    meta: '14:28 · 司机',
                    value: '路面已被淹，机动车不可通行',
                    buttonLabel: '采信 AI 推荐结论',
                    highlighted: true,
                    onPressed: onAcceptFlooded,
                  );
                  if (constraints.maxWidth < 300) {
                    return Column(
                      children: [first, const SizedBox(height: 12), second],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: first),
                      const SizedBox(width: 12),
                      Expanded(child: second),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvidenceCounter extends StatelessWidget {
  const _EvidenceCounter({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: withOpacityValue(MosaicColors.blue, 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: MosaicColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: MosaicColors.lead,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictAnalyzeButton extends StatelessWidget {
  const _ConflictAnalyzeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('analyze-conflict'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: MosaicColors.red,
          backgroundColor: withOpacityValue(MosaicColors.red, 0.06),
          side: BorderSide(color: withOpacityValue(MosaicColors.red, 0.16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 19),
        label: const Text('读取图文并调用 AI API'),
      ),
    );
  }
}

class _ConflictAnalyzingState extends StatelessWidget {
  const _ConflictAnalyzingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('conflict-analysis-loading'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: withOpacityValue(MosaicColors.purple, 0.055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: MosaicColors.purple,
                ),
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  '正在构建多模态冲突上下文…',
                  style: TextStyle(
                    color: MosaicColors.lead,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _AnalysisPipelineStep(label: '读取 2 张现场图片和 3 条文字', done: true),
          _AnalysisPipelineStep(label: '提取 OCR、视觉特征和文件指纹', done: true),
          _AnalysisPipelineStep(label: '按地点与观察时间打包完整上下文', done: true),
          _AnalysisPipelineStep(label: '调用 AI API 交叉验证真实性与可信度'),
        ],
      ),
    );
  }
}

class _AnalysisPipelineStep extends StatelessWidget {
  const _AnalysisPipelineStep({required this.label, this.done = false});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 16,
            color: done ? MosaicColors.green : MosaicColors.purple,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MosaicColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictAnalysisError extends StatelessWidget {
  const _ConflictAnalysisError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: withOpacityValue(MosaicColors.red, 0.055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: MosaicColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            key: const Key('retry-conflict-analysis'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新调用 API'),
          ),
        ],
      ),
    );
  }
}

class _ConflictAnalysisResultView extends StatelessWidget {
  const _ConflictAnalysisResultView({
    required this.result,
    required this.evidence,
    required this.onRegenerate,
  });

  final AiConflictAnalysisResult result;
  final List<ConflictEvidence> evidence;
  final VoidCallback onRegenerate;

  ConflictEvidence? _evidenceById(String id) {
    for (final item in evidence) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rankedAssessments = List<EvidenceCredibilityAssessment>.of(
      result.assessments,
    )..sort((a, b) => b.credibilityScore.compareTo(a.credibilityScore));
    return Column(
      key: const Key('conflict-api-result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: MosaicColors.purple,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'AI 多模态冲突研判',
                style: TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SectionLabel(
              result.usedRemoteApi ? 'API 已返回' : '本地演示',
              foreground: result.usedRemoteApi
                  ? MosaicColors.green
                  : MosaicColors.purple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: withOpacityValue(MosaicColors.purple, 0.055),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '已读取 ${result.imageCount} 张图片 · ${result.textCount} 条文字',
                style: const TextStyle(
                  color: MosaicColors.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.contextDigest,
                style: const TextStyle(
                  color: MosaicColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${result.engineLabel} · ${result.modelVersion} · 数据截至 ${result.dataAsOf}',
                style: const TextStyle(
                  color: MosaicColors.mutedText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 建议结论',
                    style: TextStyle(
                      color: MosaicColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    result.conclusion,
                    style: const TextStyle(
                      color: MosaicColors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: withOpacityValue(MosaicColors.green, 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.confidence}%',
                    style: const TextStyle(
                      color: MosaicColors.green,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    '综合可信度',
                    style: TextStyle(
                      color: MosaicColors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'AI 推断：水位上涨中，建议采信最新上报',
          style: TextStyle(
            color: MosaicColors.lead,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          result.reasoningSummary,
          style: const TextStyle(
            color: MosaicColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '证据真实性与可信度排序',
          style: TextStyle(
            color: MosaicColors.lead,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...rankedAssessments.map(
          (assessment) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _EvidenceAssessmentTile(
              assessment: assessment,
              evidence: _evidenceById(assessment.evidenceId),
              recommended:
                  assessment.evidenceId == result.recommendedEvidenceId,
            ),
          ),
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: withOpacityValue(MosaicColors.amber, 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '风险提示',
                  style: TextStyle(
                    color: MosaicColors.lead,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                ...result.warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $warning',
                      style: const TextStyle(
                        color: MosaicColors.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('rerun-conflict-analysis'),
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('用最新资料重新分析'),
          ),
        ),
      ],
    );
  }
}

class _EvidenceAssessmentTile extends StatelessWidget {
  const _EvidenceAssessmentTile({
    required this.assessment,
    required this.evidence,
    required this.recommended,
  });

  final EvidenceCredibilityAssessment assessment;
  final ConflictEvidence? evidence;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final item = evidence;
    final isImage = item?.modality == EvidenceModality.image;
    final accent = recommended ? MosaicColors.green : MosaicColors.blue;
    return Container(
      key: Key('evidence-assessment-${assessment.evidenceId}'),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: recommended
            ? withOpacityValue(MosaicColors.green, 0.045)
            : MosaicColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recommended
              ? withOpacityValue(MosaicColors.green, 0.25)
              : withOpacityValue(MosaicColors.lead, 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: withOpacityValue(accent, 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isImage ? Icons.image_rounded : Icons.subject_rounded,
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item?.source ?? assessment.evidenceId,
                            style: const TextStyle(
                              color: MosaicColors.lead,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (recommended)
                          const SectionLabel(
                            '最高可信',
                            foreground: MosaicColors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item?.observedAt ?? '--:--'} · ${item?.modality.label ?? '资料'}${item?.fileName == null ? '' : ' · ${item!.fileName}'}',
                      style: const TextStyle(
                        color: MosaicColors.mutedText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _ScoreChip(
                label: '真实性 ${assessment.authenticityScore}%',
                color: MosaicColors.blue,
              ),
              _ScoreChip(
                label: '可信度 ${assessment.credibilityScore}%',
                color: accent,
              ),
              _ScoreChip(
                label: assessment.verdict.label,
                color: assessment.verdict == EvidenceVerdict.contradicted
                    ? MosaicColors.red
                    : MosaicColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assessment.reason,
            style: const TextStyle(
              color: MosaicColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (assessment.extractedFacts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '提取事实：${assessment.extractedFacts.join(' · ')}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MosaicColors.mutedText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: withOpacityValue(color, 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AnalysisOption extends StatelessWidget {
  const _AnalysisOption({
    super.key,
    required this.meta,
    required this.value,
    required this.buttonLabel,
    required this.onPressed,
    this.highlighted = false,
  });

  final String meta;
  final String value;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? withOpacityValue(MosaicColors.red, 0.035)
            : MosaicColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? MosaicColors.red
              : withOpacityValue(MosaicColors.lead, 0.09),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meta,
            style: TextStyle(
              color: highlighted ? MosaicColors.red : MosaicColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? MosaicColors.red : MosaicColors.lead,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: highlighted ? const Key('accept-latest') : null,
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: highlighted
                    ? MosaicColors.red
                    : MosaicColors.white,
                foregroundColor: highlighted
                    ? MosaicColors.white
                    : MosaicColors.lead,
                side: highlighted
                    ? BorderSide.none
                    : BorderSide(
                        color: withOpacityValue(MosaicColors.lead, 0.11),
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                elevation: 0,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );

    if (!highlighted) {
      return content;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        content,
        const Positioned(
          right: -5,
          top: -9,
          child: SectionLabel(
            '推荐',
            foreground: MosaicColors.white,
            background: MosaicColors.red,
          ),
        ),
      ],
    );
  }
}

class _BlindSpotCard extends StatelessWidget {
  const _BlindSpotCard({required this.report});

  final CitizenReport? report;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = report != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MosaicColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isConfirmed
              ? withOpacityValue(MosaicColors.green, 0.3)
              : withOpacityValue(MosaicColors.lead, 0.08),
        ),
        boxShadow: isConfirmed
            ? MosaicShadow.tinted(MosaicColors.green, opacity: 0.08)
            : MosaicShadow.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel(
                isConfirmed ? '盲区已填补' : '严重盲区',
                foreground: isConfirmed
                    ? MosaicColors.green
                    : MosaicColors.lead,
              ),
              const Spacer(),
              Text(
                isConfirmed ? report!.timeLabel : '影响 60 人',
                style: const TextStyle(
                  color: MosaicColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isConfirmed ? '大关桥状态已由居民确认' : '大关桥通行状态未知',
            style: const TextStyle(
              color: MosaicColors.lead,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isConfirmed
                ? '最新反馈：${report!.content}。信息已进入路线研判，3 条配送路线正在更新。'
                : '影响 3 条配送路线，系统已向附近居民下发定向确认请求。',
            style: const TextStyle(
              color: MosaicColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentReportsCard extends StatelessWidget {
  const _UrgentReportsCard({required this.reports});

  final List<CitizenReport> reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MosaicColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: withOpacityValue(MosaicColors.red, 0.26)),
        boxShadow: MosaicShadow.tinted(MosaicColors.red, opacity: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionLabel('居民紧急上报', foreground: MosaicColors.red),
              const Spacer(),
              Text(
                '${reports.length} 条',
                style: const TextStyle(
                  color: MosaicColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < reports.length; index++) ...[
            if (index > 0) const Divider(color: MosaicColors.mapLine),
            Text(
              '${reports[index].category.label} · ${reports[index].location}',
              style: const TextStyle(
                color: MosaicColors.red,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reports[index].content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MosaicColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityReportsCard extends StatelessWidget {
  const _PriorityReportsCard({
    super.key,
    required this.title,
    required this.reports,
  });

  final String title;
  final List<CitizenReport> reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MosaicColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: withOpacityValue(MosaicColors.blue, 0.16)),
        boxShadow: MosaicShadow.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel(title, foreground: MosaicColors.blue),
              const Spacer(),
              Text(
                '${reports.length} 条',
                style: const TextStyle(
                  color: MosaicColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < reports.length; index++) ...[
            if (index > 0) const Divider(color: MosaicColors.mapLine),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  reports[index].category.icon,
                  color: reports[index].category.color,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reports[index].category.label} · ${reports[index].location}',
                        style: const TextStyle(
                          color: MosaicColors.lead,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reports[index].content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MosaicColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  reports[index].timeLabel,
                  style: const TextStyle(
                    color: MosaicColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPriorityState extends StatelessWidget {
  const _EmptyPriorityState({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: withOpacityValue(MosaicColors.lead, 0.12)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: MosaicColors.mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
