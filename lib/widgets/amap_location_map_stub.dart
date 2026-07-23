import 'package:flutter/material.dart';

import '../design_system.dart';

class AmapLocationMap extends StatelessWidget {
  const AmapLocationMap({
    super.key,
    required this.conflictResolved,
    required this.blindSpotResolved,
    required this.resolvedRoadColor,
  });

  final bool conflictResolved;
  final bool blindSpotResolved;
  final Color resolvedRoadColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('amap-web-unsupported'),
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        color: MosaicColors.background,
        border: Border(bottom: BorderSide(color: MosaicColors.mapLine)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              color: MosaicColors.blue,
              size: 38,
            ),
            const SizedBox(height: 10),
            const Text(
              '高德原生地图已接入',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MosaicColors.lead,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '高德地图 SDK Flutter 插件仅支持 Android 和 iOS，请在手机或模拟器中授权定位后查看当前位置。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MosaicColors.mutedText,
                height: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _StatusSummary(
              conflictResolved: conflictResolved,
              blindSpotResolved: blindSpotResolved,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({
    required this.conflictResolved,
    required this.blindSpotResolved,
  });

  final bool conflictResolved;
  final bool blindSpotResolved;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          label: conflictResolved ? '沿江路已研判' : '沿江路待研判',
          color: conflictResolved ? MosaicColors.green : MosaicColors.amber,
        ),
        _StatusChip(
          label: blindSpotResolved ? '大关桥已确认' : '大关桥待确认',
          color: blindSpotResolved ? MosaicColors.blue : MosaicColors.hole,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: withOpacityValue(color, 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: withOpacityValue(color, 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
