import 'package:crisismosaic/crisis_mosaic_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('command view exposes conflict analysis and resolution', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CrisisMosaicApp());

    expect(find.text('杭州 · 洪灾'), findsOneWidget);
    expect(find.text('沿江路通行状态冲突'), findsOneWidget);
    expect(find.text('大关桥通行状态未知'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('analyze-conflict')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-conflict')));
    await tester.pumpAndSettle();

    expect(find.text('AI 推断：水位上涨中，建议采信最新上报'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('accept-latest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-latest')));
    await tester.pumpAndSettle();

    expect(find.text('沿江路通行状态冲突'), findsNothing);
    await tester.drag(
      find.byKey(const PageStorageKey('command-scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('14:28 路面已被淹（已确认）'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('command-tab')));
    await tester.pumpAndSettle();
    expect(find.text('沿江路通行状态冲突'), findsNothing);
  });

  testWidgets('resident can answer the directed question', (tester) async {
    await tester.pumpWidget(const CrisisMosaicApp());

    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();
    expect(find.text('你需要什么帮助？'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bridge-task-card')));
    await tester.pumpAndSettle();
    expect(find.text('你现在能看见大关桥吗？'), findsOneWidget);

    await tester.tap(find.byKey(const Key('answer-option-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-answer')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('已收到你的碎片'), findsOneWidget);
    expect(find.textContaining('仅行人可通行 · 大关桥'), findsOneWidget);

    await tester.tap(find.byKey(const Key('return-home')));
    await tester.pumpAndSettle();
    expect(find.text('大关桥：仅行人可通行'), findsOneWidget);

    await tester.tap(find.byKey(const Key('command-tab')));
    await tester.pumpAndSettle();
    expect(find.text('大关桥状态已由居民确认'), findsOneWidget);
    expect(find.text('盲区已填补'), findsOneWidget);
  });

  testWidgets('all quick report entries open a working form', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CrisisMosaicApp());
    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();

    for (final category in [
      'rescue',
      'medical',
      'water',
      'food',
      'shelter',
      'road',
    ]) {
      final action = find.byKey(Key('report-action-$category'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quick-report-form')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel-report')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('quick report can be submitted, edited and synced', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CrisisMosaicApp());
    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-action-rescue')));
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('submit-report'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('report-content')),
      '运河西岸有3人被困',
    );
    await tester.tap(find.byKey(const Key('urgent-switch')));
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('已收到你的碎片'), findsOneWidget);
    expect(find.text('信息已同步至指挥视角'), findsOneWidget);
    await tester.tap(find.byKey(const Key('return-home')));
    await tester.pumpAndSettle();
    expect(find.text('运河西岸有3人被困'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-recent-report')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-content')),
      '运河西岸有4人被困，水位仍在上涨',
    );
    await tester.tap(find.byKey(const Key('submit-report')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('信息已更新'), findsOneWidget);

    await tester.tap(find.byKey(const Key('return-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('command-tab')));
    await tester.pumpAndSettle();
    expect(find.textContaining('运河西岸有4人被困'), findsWidgets);
  });

  testWidgets('narrow phone viewport has no layout exceptions', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.2),
        ),
        child: const CrisisMosaicApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fragment cards expose contextual details', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CrisisMosaicApp());
    await tester.drag(
      find.byKey(const PageStorageKey('command-scroll')),
      const Offset(0, -1100),
    );
    await tester.pumpAndSettle();
    final fragment = find.text('A 社区');
    expect(fragment, findsOneWidget);
    await tester.tap(fragment);
    await tester.pumpAndSettle();

    expect(find.text('综合置信度'), findsOneWidget);
    expect(find.text('模拟观察员'), findsOneWidget);
    await tester.tap(find.byKey(const Key('close-fragment-detail')));
    await tester.pumpAndSettle();
    expect(find.text('综合置信度'), findsNothing);
  });

  testWidgets('large text remains scrollable without overflow', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const CrisisMosaicApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI report refinement and command brief are interactive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CrisisMosaicApp());
    await tester.ensureVisible(find.byKey(const Key('generate-ai-brief')));
    await tester.tap(find.byKey(const Key('generate-ai-brief')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('仍有关键决策风险'), findsOneWidget);
    expect(find.textContaining('置信度'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resident-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-action-rescue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-content')),
      '有3名老人被困 急需救援',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-content')))
          .controller!
          .text,
      '有3名老人被困 急需救援',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-location')))
          .controller!
          .text,
      isNotEmpty,
    );
    await tester.ensureVisible(find.byKey(const Key('ai-refine-report')));
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('ai-refine-report')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('ai-refine-report')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-content')))
          .controller!
          .text,
      contains('【需要救援】'),
    );
    await tester.drag(
      find.byKey(const Key('quick-report-form')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('检测到高风险关键词'), findsOneWidget);
    final urgentSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('urgent-switch')),
    );
    expect(urgentSwitch.value, isTrue);
  });
}
