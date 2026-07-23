import 'package:flutter/material.dart';

import '../design_system.dart';
import '../models/info_fragment.dart';
import 'map_panel.dart';

class FragmentCard extends StatelessWidget {
  const FragmentCard({
    super.key,
    required this.fragment,
    this.isConflict = false,
    this.onTap,
  });

  final InfoFragment fragment;
  final bool isConflict;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBlind = fragment.status == FragmentStatus.blind;
    final foreground = isBlind ? const Color(0xFFD0CDCA) : MosaicColors.lead;
    final secondary = isBlind
        ? const Color(0xFF9A9692)
        : MosaicColors.secondaryText;

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isBlind ? MosaicColors.hole : MosaicColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isConflict
                  ? withOpacityValue(MosaicColors.amber, 0.34)
                  : withOpacityValue(MosaicColors.lead, 0.06),
            ),
            boxShadow: isConflict
                ? MosaicShadow.tinted(MosaicColors.amber, opacity: 0.11)
                : MosaicShadow.subtle,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBlind
                      ? const Color(0xFF242326)
                      : withOpacityValue(fragment.color, 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ShapeGlyph(
                  shape: fragment.shape,
                  color: isBlind ? const Color(0xFF888888) : fragment.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          fragment.label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (isConflict)
                          const SectionLabel(
                            '冲突',
                            foreground: MosaicColors.amber,
                          ),
                        if (isBlind)
                          const SectionLabel(
                            '盲区',
                            foreground: Color(0xFFEAE7E3),
                            background: Color(0xFF303034),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fragment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (fragment.time.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  fragment.time,
                  style: const TextStyle(
                    color: MosaicColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ConflictConnector extends StatelessWidget {
  const ConflictConnector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ConflictConnectorPainter(), child: child);
  }
}

class _ConflictConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = withOpacityValue(MosaicColors.amber, 0.48)
      ..strokeWidth = 2;
    const dashHeight = 5.0;
    const gap = 4.0;
    var y = 31.0;
    while (y < size.height - 31) {
      canvas.drawLine(
        const Offset(40, 0) + Offset(0, y),
        const Offset(40, 0) + Offset(0, (y + dashHeight).clamp(0, size.height)),
        paint,
      );
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
