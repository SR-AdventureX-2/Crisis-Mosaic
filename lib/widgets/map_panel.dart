import 'package:flutter/material.dart';

import '../design_system.dart';
import '../models/info_fragment.dart';
import 'amap_location_map.dart';

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
      label: '高德地图与当前位置',
      child: AmapLocationMap(
        key: const Key('amap-location-map'),
        conflictResolved: conflictResolved,
        blindSpotResolved: blindSpotResolved,
        resolvedRoadColor: resolvedRoadColor,
      ),
    );
  }
}
