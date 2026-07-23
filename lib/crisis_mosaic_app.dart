import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_system.dart';
import 'models/citizen_report.dart';
import 'models/conflict_analysis.dart';
import 'screens/command_screen.dart';
import 'screens/resident_screens.dart';
import 'services/ai_analysis_service.dart';
import 'widgets/role_navigation.dart';

enum MosaicScreen { command, resident, question, report, success }

class CrisisMosaicApp extends StatelessWidget {
  const CrisisMosaicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crisis Mosaic',
      debugShowCheckedModeBanner: false,
      theme: buildMosaicTheme(),
      home: const CrisisMosaicShell(),
    );
  }
}

class CrisisMosaicShell extends StatefulWidget {
  const CrisisMosaicShell({super.key});

  @override
  State<CrisisMosaicShell> createState() => _CrisisMosaicShellState();
}

class _CrisisMosaicShellState extends State<CrisisMosaicShell> {
  MosaicScreen _screen = MosaicScreen.command;
  RoleTab _activeTab = RoleTab.command;
  final List<CitizenReport> _reports = [];
  ReportCategory _draftCategory = ReportCategory.rescue;
  CitizenReport? _editingReport;
  int _nextReportId = 1;
  bool _conflictAnalyzing = false;
  AiConflictAnalysisResult? _conflictAnalysis;
  String? _conflictAnalysisError;
  bool _conflictResolved = false;
  bool _roadFlooded = true;

  String _successTitle = '已收到你的碎片';
  String _successMessage = '信息已同步至指挥视角';
  String _successSummary = '';
  String _successLocation = '';
  String _successTimeLabel = '';

  bool get _showsNavigation {
    return _screen == MosaicScreen.command || _screen == MosaicScreen.resident;
  }

  void _selectTab(RoleTab tab) {
    setState(() {
      _activeTab = tab;
      _screen = switch (tab) {
        RoleTab.command => MosaicScreen.command,
        RoleTab.resident => MosaicScreen.resident,
      };
    });
  }

  void _openTask() {
    setState(() => _screen = MosaicScreen.question);
  }

  void _openReport(ReportCategory category) {
    setState(() {
      _draftCategory = category;
      _editingReport = null;
      _screen = MosaicScreen.report;
    });
  }

  void _editRecentReport() {
    final recent = _recentEditableReport;
    if (recent == null) {
      return;
    }
    setState(() {
      _draftCategory = recent.category;
      _editingReport = recent;
      _screen = MosaicScreen.report;
    });
  }

  void _cancelReport() {
    setState(() {
      _editingReport = null;
      _screen = MosaicScreen.resident;
    });
  }

  void _submitQuickReport(String content, String location, bool isUrgent) {
    final now = DateTime.now();
    final existing = _editingReport;
    late final CitizenReport report;

    if (existing == null) {
      report = CitizenReport(
        id: 'local-${_nextReportId++}',
        category: _draftCategory,
        content: content,
        location: location,
        createdAt: now,
        updatedAt: now,
        isUpdated: false,
        isUrgent: isUrgent,
      );
      _reports.add(report);
    } else {
      report = existing.copyWith(
        content: content,
        location: location,
        updatedAt: now,
        isUpdated: true,
        isUrgent: isUrgent,
      );
      final index = _reports.indexWhere((item) => item.id == existing.id);
      if (index >= 0) {
        _reports[index] = report;
      }
    }

    setState(() {
      _editingReport = null;
      _successTitle = existing == null ? '已收到你的碎片' : '信息已更新';
      _successMessage = existing == null ? '信息已同步至指挥视角' : '最新情况已替换原上报';
      _successSummary = report.content;
      _successLocation = report.location;
      _successTimeLabel = report.timeLabel;
      _screen = MosaicScreen.success;
    });
  }

  void _submitDirectedAnswer(String answer) {
    final now = DateTime.now();
    final existingIndex = _reports.indexWhere(
      (report) => report.isDirectedAnswer,
    );
    final report = CitizenReport(
      id: existingIndex >= 0
          ? _reports[existingIndex].id
          : 'directed-${_nextReportId++}',
      category: ReportCategory.road,
      content: answer,
      location: '大关桥',
      createdAt: existingIndex >= 0 ? _reports[existingIndex].createdAt : now,
      updatedAt: now,
      isUpdated: existingIndex >= 0,
      isUrgent: false,
      isDirectedAnswer: true,
    );
    if (existingIndex >= 0) {
      _reports[existingIndex] = report;
    } else {
      _reports.add(report);
    }

    setState(() {
      _successTitle = existingIndex >= 0 ? '确认信息已更新' : '已收到你的碎片';
      _successMessage = '你的信息正在影响 3 条救援路线';
      _successSummary = answer;
      _successLocation = '大关桥';
      _successTimeLabel = report.timeLabel;
      _screen = MosaicScreen.success;
    });
  }

  Future<void> _analyzeConflict() async {
    if (_conflictAnalyzing) {
      return;
    }
    setState(() {
      _conflictAnalyzing = true;
      _conflictAnalysisError = null;
    });
    try {
      final result = await aiAnalysisService.analyzeConflict(
        conflictId: 'along-river-road-passability',
        conflictRevision: 1,
        location: '沿江路东段',
        topic: 'road_passability',
        evidence: demoRoadConflictEvidence,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _conflictAnalysis = result;
        _conflictAnalyzing = false;
      });
    } on AiAnalysisException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _conflictAnalyzing = false;
        _conflictAnalysisError = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _conflictAnalyzing = false;
        _conflictAnalysisError = '冲突分析暂时不可用，请稍后重试。';
      });
    }
  }

  void _resolveConflict(bool roadFlooded) {
    setState(() {
      _roadFlooded = roadFlooded;
      _conflictResolved = true;
    });
  }

  CitizenReport? get _recentEditableReport {
    final editable =
        _reports
            .where((report) => !report.isDirectedAnswer)
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return editable.isEmpty ? null : editable.first;
  }

  CitizenReport? get _directedReport {
    for (final report in _reports) {
      if (report.isDirectedAnswer) {
        return report;
      }
    }
    return null;
  }

  List<CitizenReport> get _sortedReports {
    final reports = List<CitizenReport>.of(_reports)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return reports;
  }

  void _returnToResidentHome() {
    setState(() {
      _activeTab = RoleTab.resident;
      _screen = MosaicScreen.resident;
    });
  }

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: MosaicColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: MosaicColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return PopScope<Object?>(
      canPop: _screen == MosaicScreen.command,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_screen == MosaicScreen.resident) {
          _selectTab(RoleTab.command);
        } else {
          _returnToResidentHome();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: MosaicColors.desktopBackground,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 430;
              return Center(
                child: Container(
                  width: constraints.maxWidth.clamp(0, 430).toDouble(),
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: MosaicColors.background,
                    boxShadow: isWide
                        ? const [
                            BoxShadow(
                              color: Color(0x24000000),
                              blurRadius: 32,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [...previousChildren, ?currentChild],
                              );
                            },
                            child: _buildScreen(),
                          ),
                        ),
                        if (_showsNavigation)
                          BottomRoleNavigation(
                            active: _activeTab,
                            onSelected: _selectTab,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return switch (_screen) {
      MosaicScreen.command => CommandScreen(
        key: ValueKey(MosaicScreen.command),
        citizenReports: _sortedReports,
        directedReport: _directedReport,
        conflictAnalyzing: _conflictAnalyzing,
        conflictAnalysis: _conflictAnalysis,
        conflictAnalysisError: _conflictAnalysisError,
        conflictResolved: _conflictResolved,
        roadFlooded: _roadFlooded,
        onAnalyzeConflict: _analyzeConflict,
        onResolveConflict: _resolveConflict,
      ),
      MosaicScreen.resident => ResidentHomeScreen(
        key: const ValueKey(MosaicScreen.resident),
        onOpenTask: _openTask,
        onOpenReport: _openReport,
        recentReport: _recentEditableReport,
        directedReport: _directedReport,
        onEditRecent: _editRecentReport,
      ),
      MosaicScreen.question => BridgeQuestionScreen(
        key: const ValueKey(MosaicScreen.question),
        onSubmitted: _submitDirectedAnswer,
        onCancel: _cancelReport,
        initialAnswer: _directedReport?.content,
      ),
      MosaicScreen.report => QuickReportScreen(
        key: ValueKey(
          'report-${_draftCategory.name}-${_editingReport?.id ?? 'new'}',
        ),
        category: _draftCategory,
        existingReport: _editingReport,
        onCancel: _cancelReport,
        onSubmitted: _submitQuickReport,
      ),
      MosaicScreen.success => SubmissionSuccessScreen(
        key: const ValueKey(MosaicScreen.success),
        title: _successTitle,
        message: _successMessage,
        summary: _successSummary,
        location: _successLocation,
        timeLabel: _successTimeLabel,
        onBack: _returnToResidentHome,
      ),
    };
  }
}
