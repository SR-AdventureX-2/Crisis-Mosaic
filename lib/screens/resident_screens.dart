import 'package:flutter/material.dart';

import '../design_system.dart';
import '../models/citizen_report.dart';
import '../services/ai_analysis_service.dart';

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({
    super.key,
    required this.onOpenTask,
    required this.onOpenReport,
    required this.recentReport,
    required this.directedReport,
    required this.onEditRecent,
  });

  final VoidCallback onOpenTask;
  final ValueChanged<ReportCategory> onOpenReport;
  final CitizenReport? recentReport;
  final CitizenReport? directedReport;
  final VoidCallback onEditRecent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MosaicColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 350;
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          return CustomScrollView(
            key: const PageStorageKey('resident-scroll'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  recentReport == null ? 24 : 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: _TaskCard(
                    onTap: onOpenTask,
                    completedReport: directedReport,
                  ),
                ),
              ),
              if (recentReport case final report?)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _RecentReportCard(
                      report: report,
                      onEdit: onEditRecent,
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '你需要什么帮助？',
                    style: TextStyle(
                      color: MosaicColors.lead,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: textScale > 1.5
                        ? 0.95
                        : (compact ? 1 : 1.26),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: ReportCategory.values.length,
                    (context, index) {
                      final category = ReportCategory.values[index];
                      return _ReportActionCard(
                        category: category,
                        onTap: () => onOpenReport(category),
                      );
                    },
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '无需注册 · 匿名上报 · 实时同步',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MosaicColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.onTap, required this.completedReport});

  final VoidCallback onTap;
  final CitizenReport? completedReport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MosaicColors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const Key('bridge-task-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: withOpacityValue(MosaicColors.amber, 0.28),
            ),
            boxShadow: MosaicShadow.tinted(MosaicColors.amber, opacity: 0.11),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ProductMark(size: 30, borderRadius: 9),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SectionLabel(
                        completedReport == null ? '定向确认请求' : '已完成 · 可重新确认',
                        foreground: completedReport == null
                            ? MosaicColors.amber
                            : MosaicColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                completedReport == null
                    ? '你现在能看见大关桥吗？'
                    : '大关桥：${completedReport!.content}',
                style: const TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      completedReport == null
                          ? '点击回答 · 影响 3 条救援路线'
                          : '已同步至指挥视角 · 点击更新',
                      style: const TextStyle(
                        color: MosaicColors.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: completedReport == null
                        ? MosaicColors.amber
                        : MosaicColors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentReportCard extends StatelessWidget {
  const _RecentReportCard({required this.report, required this.onEdit});

  final CitizenReport report;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MosaicColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: withOpacityValue(report.category.color, 0.2)),
        boxShadow: MosaicShadow.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel(
                report.isUpdated ? '最近上报 · 已更新' : '最近上报 · 已提交',
                foreground: MosaicColors.green,
              ),
              const Spacer(),
              Text(
                report.timeLabel,
                style: const TextStyle(
                  color: MosaicColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            report.category.label,
            style: const TextStyle(
              color: MosaicColors.lead,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            report.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MosaicColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: MosaicColors.mutedText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MosaicColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                key: const Key('edit-recent-report'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('修改'),
                style: TextButton.styleFrom(
                  foregroundColor: MosaicColors.blue,
                  minimumSize: const Size(72, 44),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportActionCard extends StatelessWidget {
  const _ReportActionCard({required this.category, required this.onTap});

  final ReportCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MosaicColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: Key('report-action-${category.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: withOpacityValue(MosaicColors.lead, 0.055),
            ),
            boxShadow: MosaicShadow.subtle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: withOpacityValue(category.color, 0.07),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(category.icon, size: 29, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickReportScreen extends StatefulWidget {
  const QuickReportScreen({
    super.key,
    required this.category,
    required this.existingReport,
    required this.onCancel,
    required this.onSubmitted,
  });

  final ReportCategory category;
  final CitizenReport? existingReport;
  final VoidCallback onCancel;
  final void Function(String content, String location, bool isUrgent)
  onSubmitted;

  @override
  State<QuickReportScreen> createState() => _QuickReportScreenState();
}

class _QuickReportScreenState extends State<QuickReportScreen> {
  late final TextEditingController _contentController;
  late final TextEditingController _locationController;
  late bool _isUrgent;
  bool _sending = false;
  bool _aiWorking = false;
  String? _aiHint;

  bool get _canSubmit =>
      _contentController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      !_sending &&
      !_aiWorking;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReport;
    _contentController = TextEditingController(text: existing?.content ?? '');
    _locationController = TextEditingController(
      text: existing?.location ?? '杭州市拱墅区 · 当前位置',
    );
    _isUrgent = existing?.isUrgent ?? false;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) {
      return;
    }
    widget.onSubmitted(
      _contentController.text.trim(),
      _locationController.text.trim(),
      _isUrgent,
    );
  }

  Future<void> _refineWithAi() async {
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();
    if (content.isEmpty || location.isEmpty || _sending || _aiWorking) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _aiWorking = true;
      _aiHint = null;
    });
    final suggestion = await aiAnalysisService.refineReport(
      category: widget.category,
      content: content,
      location: location,
    );
    if (!mounted) {
      return;
    }
    final refined = suggestion.refinedContent.length > 300
        ? suggestion.refinedContent.substring(0, 300)
        : suggestion.refinedContent;
    _contentController
      ..text = refined
      ..selection = TextSelection.collapsed(offset: refined.length);
    setState(() {
      _aiWorking = false;
      _aiHint = suggestion.riskHint;
      if (suggestion.suggestUrgent) {
        _isUrgent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final isEditing = widget.existingReport != null;

    return ColoredBox(
      color: MosaicColors.background,
      child: ListView(
        key: const Key('quick-report-form'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('cancel-report'),
                onPressed: _sending || _aiWorking ? null : widget.onCancel,
                tooltip: '返回居民首页',
                style: IconButton.styleFrom(
                  foregroundColor: MosaicColors.lead,
                  backgroundColor: MosaicColors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              SectionLabel(
                isEditing ? '修改最近上报' : '匿名现场上报',
                foreground: category.color,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: withOpacityValue(category.color, 0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, color: category.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.pageTitle,
                      style: const TextStyle(
                        color: MosaicColors.lead,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '信息会立即同步到指挥视角',
                      style: TextStyle(
                        color: MosaicColors.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _FormFieldLabel(label: '位置', icon: Icons.location_on_outlined),
          const SizedBox(height: 8),
          TextField(
            key: const Key('report-location'),
            controller: _locationController,
            enabled: !_sending && !_aiWorking,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(
              hintText: '请输入或确认当前位置',
              suffixIcon: IconButton(
                key: const Key('use-current-location'),
                onPressed: _sending
                    ? null
                    : () {
                        _locationController.text = '杭州市拱墅区 · 当前位置';
                        setState(() {});
                      },
                tooltip: '使用当前位置',
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: MosaicColors.blue,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _FormFieldLabel(label: '现场信息', icon: Icons.notes_rounded),
          const SizedBox(height: 8),
          TextField(
            key: const Key('report-content'),
            controller: _contentController,
            enabled: !_sending && !_aiWorking,
            minLines: 5,
            maxLines: 8,
            maxLength: 300,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hintText: category.prompt),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            key: const Key('ai-refine-report'),
            onPressed: _sending || _aiWorking ? null : _refineWithAi,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: MosaicColors.purple,
              backgroundColor: withOpacityValue(MosaicColors.purple, 0.05),
              disabledForegroundColor: MosaicColors.mutedText,
              side: BorderSide(
                color: withOpacityValue(MosaicColors.purple, 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: _aiWorking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MosaicColors.purple,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 19),
            label: Text(_aiWorking ? 'AI 正在整理…' : 'AI 智能整理并识别风险'),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _aiHint == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(_aiHint),
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: withOpacityValue(MosaicColors.purple, 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: MosaicColors.purple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _aiHint!,
                            style: const TextStyle(
                              color: MosaicColors.lead,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Material(
            color: MosaicColors.white,
            borderRadius: BorderRadius.circular(16),
            child: SwitchListTile.adaptive(
              key: const Key('urgent-switch'),
              value: _isUrgent,
              onChanged: _sending || _aiWorking
                  ? null
                  : (value) => setState(() => _isUrgent = value),
              activeTrackColor: MosaicColors.red,
              secondary: const Icon(
                Icons.priority_high_rounded,
                color: MosaicColors.red,
              ),
              title: const Text(
                '情况紧急',
                style: TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                '紧急信息会在指挥端优先显示',
                style: TextStyle(
                  color: MosaicColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: withOpacityValue(MosaicColors.lead, 0.07),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            key: const Key('submit-report'),
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: MosaicColors.lead,
              disabledBackgroundColor: withOpacityValue(MosaicColors.lead, 0.1),
              foregroundColor: MosaicColors.white,
              disabledForegroundColor: withOpacityValue(
                MosaicColors.lead,
                0.38,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: MosaicColors.white,
                    ),
                  )
                : Text(isEditing ? '更新信息' : '提交信息'),
          ),
          const SizedBox(height: 13),
          const Text(
            '无需姓名或手机号 · 提交后可继续修改',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MosaicColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: MosaicColors.mutedText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      filled: true,
      fillColor: MosaicColors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: withOpacityValue(MosaicColors.lead, 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MosaicColors.blue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: withOpacityValue(MosaicColors.lead, 0.05),
        ),
      ),
    );
  }
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MosaicColors.lead, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: MosaicColors.lead,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class BridgeQuestionScreen extends StatefulWidget {
  const BridgeQuestionScreen({
    super.key,
    required this.onSubmitted,
    required this.onCancel,
    this.initialAnswer,
  });

  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;
  final String? initialAnswer;

  @override
  State<BridgeQuestionScreen> createState() => _BridgeQuestionScreenState();
}

class _BridgeQuestionScreenState extends State<BridgeQuestionScreen> {
  static const _options = ['车辆可通行', '仅行人可通行', '完全中断', '无法判断'];

  late String? _selected;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialAnswer;
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null || _sending) {
      return;
    }
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }
    widget.onSubmitted(selected);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MosaicColors.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('cancel-question'),
                      onPressed: _sending ? null : widget.onCancel,
                      tooltip: '返回居民首页',
                      style: IconButton.styleFrom(
                        foregroundColor: MosaicColors.lead,
                        backgroundColor: MosaicColors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    const SectionLabel('定向确认请求', foreground: Color(0xFFB38128)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '你现在能看见大关桥吗？',
                  style: TextStyle(
                    color: MosaicColors.lead,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '大关桥目前通行状态未知，影响 3 条救援路线。',
                  style: TextStyle(
                    color: MosaicColors.secondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              itemCount: _options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _options[index];
                return _QuestionOption(
                  key: Key('answer-option-$index'),
                  label: option,
                  selected: option == _selected,
                  onTap: _sending
                      ? null
                      : () => setState(() => _selected = option),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('submit-answer'),
                    onPressed: _selected != null && !_sending ? _submit : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: MosaicColors.lead,
                      disabledBackgroundColor: withOpacityValue(
                        MosaicColors.lead,
                        0.1,
                      ),
                      foregroundColor: MosaicColors.white,
                      disabledForegroundColor: withOpacityValue(
                        MosaicColors.lead,
                        0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: MosaicColors.white,
                            ),
                          )
                        : const Text('提交'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '匿名上报 · 无需注册',
                  style: TextStyle(
                    color: MosaicColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionOption extends StatelessWidget {
  const _QuestionOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.015 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: selected ? MosaicColors.blue : MosaicColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? MosaicColors.blue
                    : withOpacityValue(MosaicColors.lead, 0.08),
              ),
              boxShadow: selected
                  ? MosaicShadow.tinted(MosaicColors.blue, opacity: 0.19)
                  : MosaicShadow.subtle,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? MosaicColors.white : MosaicColors.lead,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: MosaicColors.white,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({
    super.key,
    required this.title,
    required this.message,
    required this.summary,
    required this.location,
    required this.timeLabel,
    required this.onBack,
  });

  final String title;
  final String message;
  final String summary;
  final String location;
  final String timeLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MosaicColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MosaicColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: withOpacityValue(MosaicColors.lead, 0.05),
                  ),
                  boxShadow: MosaicShadow.tinted(
                    MosaicColors.green,
                    opacity: 0.14,
                  ),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: withOpacityValue(MosaicColors.green, 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: MosaicColors.green,
                    size: 38,
                    weight: 700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MosaicColors.lead,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MosaicColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: withOpacityValue(MosaicColors.lead, 0.045),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$summary · $location · $timeLabel',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: MosaicColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('return-home'),
                  onPressed: onBack,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: MosaicColors.lead,
                    foregroundColor: MosaicColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  child: const Text('返回首页'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
