import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design_system.dart';
import '../models/info_fragment.dart';

class ShapeGlyph extends StatelessWidget {
  const ShapeGlyph({
    super.key,
    required this.shape,
    required this.color,
    this.size = 20,
  });

  final FragmentShape shape;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ShapeGlyphPainter(shape: shape, color: color),
    );
  }
}

class _ShapeGlyphPainter extends CustomPainter {
  const _ShapeGlyphPainter({required this.shape, required this.color});

  final FragmentShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 20;
    canvas.save();
    canvas.scale(scale);

    final fill = Paint()
      ..color = withOpacityValue(color, 0.76)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = MosaicColors.lead
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (shape) {
      case FragmentShape.circle:
        canvas.drawCircle(const Offset(10, 10), 8, fill);
        canvas.drawCircle(const Offset(10, 10), 8, stroke);
      case FragmentShape.triangle:
        final path = Path()
          ..moveTo(10, 2)
          ..lineTo(18, 18)
          ..lineTo(2, 18)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case FragmentShape.cross:
        final path = Path()
          ..addRect(const Rect.fromLTWH(8, 2, 4, 16))
          ..addRect(const Rect.fromLTWH(2, 8, 16, 4));
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case FragmentShape.bar:
        final rect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 7, 16, 6),
          const Radius.circular(1),
        );
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, stroke);
      case FragmentShape.diamond:
        final path = Path()
          ..moveTo(10, 1)
          ..lineTo(19, 10)
          ..lineTo(10, 19)
          ..lineTo(1, 10)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case FragmentShape.hole:
        final holeFill = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(const Offset(10, 10), 8, holeFill);
        canvas.drawCircle(const Offset(10, 10), 8, stroke);
        canvas.drawCircle(
          const Offset(10, 10),
          3,
          Paint()..color = withOpacityValue(MosaicColors.background, 0.3),
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShapeGlyphPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}

class MapPanel extends StatelessWidget {
  const MapPanel({
    super.key,
    required this.conflictResolved,
    this.blindSpotResolved = false,
    this.resolvedRoadColor = MosaicColors.red,
  });

  final bool conflictResolved;
  final bool blindSpotResolved;
  final Color resolvedRoadColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: [
        '杭州洪灾模拟地图',
        conflictResolved ? '沿江路冲突已处理' : '沿江路存在两条冲突信息',
        blindSpotResolved ? '大关桥状态已确认' : '大关桥为信息盲区',
      ].join('，'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = math.min(210.0, constraints.maxWidth * 200 / 360);
          return Container(
            width: double.infinity,
            height: height,
            decoration: const BoxDecoration(
              color: MosaicColors.background,
              border: Border(bottom: BorderSide(color: MosaicColors.mapLine)),
            ),
            child: CustomPaint(
              painter: _MosaicMapPainter(
                conflictResolved: conflictResolved,
                blindSpotResolved: blindSpotResolved,
                resolvedRoadColor: resolvedRoadColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MosaicMapPainter extends CustomPainter {
  const _MosaicMapPainter({
    required this.conflictResolved,
    required this.blindSpotResolved,
    required this.resolvedRoadColor,
  });

  final bool conflictResolved;
  final bool blindSpotResolved;
  final Color resolvedRoadColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 360;
    final sy = size.height / 200;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 200),
      Paint()..color = MosaicColors.background,
    );

    final riverPath = Path()
      ..moveTo(60, 40)
      ..cubicTo(100, 60, 100, 60, 140, 80)
      ..cubicTo(180, 100, 180, 100, 220, 110)
      ..cubicTo(260, 120, 260, 120, 300, 130);
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0x80A8C8E8)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0x66C8DFF0)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    _drawLine(canvas, const Offset(20, 90), const Offset(340, 90), 2);
    _drawLine(canvas, const Offset(20, 140), const Offset(340, 140), 1.5);
    _drawLine(canvas, const Offset(20, 60), const Offset(340, 60), 1);
    _drawLine(canvas, const Offset(80, 20), const Offset(80, 180), 2);
    _drawLine(canvas, const Offset(160, 20), const Offset(160, 180), 1.5);
    _drawLine(canvas, const Offset(240, 20), const Offset(240, 180), 2);
    _drawLine(canvas, const Offset(300, 20), const Offset(300, 180), 1);

    _drawText(
      canvas,
      '沿江路',
      const Offset(22, 76),
      fontSize: 7,
      color: withOpacityValue(MosaicColors.lead, 0.62),
    );

    if (blindSpotResolved) {
      _drawRoundedFragment(
        canvas,
        const Rect.fromLTWH(146, 85.5, 28, 9),
        withOpacityValue(MosaicColors.blue, 0.86),
      );
      canvas.drawCircle(
        const Offset(175, 82),
        3,
        Paint()..color = MosaicColors.green,
      );
    } else {
      canvas.drawCircle(
        const Offset(160, 90),
        12,
        Paint()..color = withOpacityValue(MosaicColors.hole, 0.86),
      );
      canvas.drawCircle(
        const Offset(160, 90),
        5,
        Paint()..color = withOpacityValue(MosaicColors.background, 0.2),
      );
    }
    _drawCenteredText(
      canvas,
      blindSpotResolved ? '大关桥 · 已确认' : '大关桥',
      const Offset(160, 100),
      fontSize: 7,
      color: withOpacityValue(MosaicColors.lead, 0.72),
    );

    if (conflictResolved) {
      _drawRoundedFragment(
        canvas,
        const Rect.fromLTWH(64, 85, 28, 9),
        withOpacityValue(resolvedRoadColor, 0.86),
      );
    } else {
      _drawRoundedFragment(
        canvas,
        const Rect.fromLTWH(62, 83, 28, 9),
        withOpacityValue(MosaicColors.blue, 0.82),
      );
      _drawRoundedFragment(
        canvas,
        const Rect.fromLTWH(66, 87, 28, 9),
        withOpacityValue(MosaicColors.blue, 0.66),
      );
      canvas.drawCircle(
        const Offset(75, 82),
        3,
        Paint()..color = MosaicColors.amber,
      );
      canvas.drawCircle(
        const Offset(75, 82),
        3,
        Paint()
          ..color = MosaicColors.lead
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }

    _drawCommunity(canvas);
    _drawWarehouse(canvas);
    _drawHospital(canvas);
    _drawShelter(canvas);

    _drawRightAlignedText(
      canvas,
      '模拟演练数据 · 杭州',
      const Offset(340, 187),
      fontSize: 6,
      color: withOpacityValue(MosaicColors.lead, 0.38),
    );

    canvas.restore();
  }

  void _drawLine(Canvas canvas, Offset from, Offset to, double width) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = MosaicColors.mapLine
        ..strokeWidth = width,
    );
  }

  void _drawRoundedFragment(Canvas canvas, Rect rect, Color color) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1));
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = MosaicColors.lead
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawCommunity(Canvas canvas) {
    canvas.drawCircle(
      const Offset(55, 130),
      9,
      Paint()..color = withOpacityValue(MosaicColors.amber, 0.76),
    );
    canvas.drawCircle(
      const Offset(55, 130),
      9,
      Paint()
        ..color = MosaicColors.lead
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    _drawCenteredText(
      canvas,
      'A',
      const Offset(55, 124),
      fontSize: 6,
      color: MosaicColors.lead,
      fontWeight: FontWeight.w700,
    );
    _drawCenteredText(
      canvas,
      '社区',
      const Offset(55, 139),
      fontSize: 6,
      color: withOpacityValue(MosaicColors.lead, 0.72),
    );
  }

  void _drawWarehouse(Canvas canvas) {
    final path = Path()
      ..moveTo(240, 55)
      ..lineTo(250, 75)
      ..lineTo(230, 75)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = withOpacityValue(MosaicColors.green, 0.76),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = MosaicColors.lead
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    _drawCenteredText(
      canvas,
      'B仓库',
      const Offset(240, 78),
      fontSize: 6,
      color: withOpacityValue(MosaicColors.lead, 0.72),
    );
  }

  void _drawHospital(Canvas canvas) {
    final fill = Paint()..color = withOpacityValue(MosaicColors.red, 0.82);
    canvas.drawRect(const Rect.fromLTWH(293, 118, 4, 14), fill);
    canvas.drawRect(const Rect.fromLTWH(288, 123, 14, 4), fill);
    final stroke = Paint()
      ..color = MosaicColors.lead
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(const Rect.fromLTWH(293, 118, 4, 14), stroke);
    canvas.drawRect(const Rect.fromLTWH(288, 123, 14, 4), stroke);
    _drawCenteredText(
      canvas,
      'C医院',
      const Offset(300, 132),
      fontSize: 6,
      color: withOpacityValue(MosaicColors.lead, 0.72),
    );
  }

  void _drawShelter(Canvas canvas) {
    final path = Path()
      ..moveTo(110, 150)
      ..lineTo(120, 160)
      ..lineTo(110, 170)
      ..lineTo(100, 160)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = withOpacityValue(MosaicColors.purple, 0.76),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = MosaicColors.lead
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    _drawCenteredText(
      canvas,
      '文体中心',
      const Offset(110, 172),
      fontSize: 6,
      color: withOpacityValue(MosaicColors.lead, 0.72),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(offset.dx - painter.width / 2, offset.dy));
  }

  void _drawRightAlignedText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(offset.dx - painter.width, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _MosaicMapPainter oldDelegate) {
    return oldDelegate.conflictResolved != conflictResolved ||
        oldDelegate.blindSpotResolved != blindSpotResolved ||
        oldDelegate.resolvedRoadColor != resolvedRoadColor;
  }
}
