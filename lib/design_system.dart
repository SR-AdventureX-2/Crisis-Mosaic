import 'package:flutter/material.dart';

abstract final class MosaicColors {
  static const background = Color(0xFFF7F4EF);
  static const mapLine = Color(0xFFE6E0D5);
  static const lead = Color(0xFF2E2A26);
  static const red = Color(0xFFA63A46);
  static const blue = Color(0xFF2456A6);
  static const amber = Color(0xFFD9A441);
  static const green = Color(0xFF2E7D5B);
  static const purple = Color(0xFF6B4E9B);
  static const hole = Color(0xFF0B0A0C);
  static const white = Colors.white;
  static const secondaryText = Color(0xFF79736D);
  static const mutedText = Color(0xFF9A948E);
  static const desktopBackground = Color(0xFFE9E4DC);
}

Color withOpacityValue(Color color, double opacity) {
  return color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

ThemeData buildMosaicTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MosaicColors.blue,
    brightness: Brightness.light,
    surface: MosaicColors.white,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSC',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MosaicColors.background,
    splashFactory: InkRipple.splashFactory,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: MosaicColors.lead,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: MosaicColors.secondaryText,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class MosaicShadow {
  const MosaicShadow._();

  static const subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> tinted(Color color, {double opacity = 0.12}) => [
    BoxShadow(
      color: withOpacityValue(color, opacity),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.foreground = MosaicColors.lead,
    this.background,
  });

  final String text;
  final Color foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? withOpacityValue(foreground, 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class ProductMark extends StatelessWidget {
  const ProductMark({super.key, this.size = 28, this.borderRadius = 8});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Crisis Mosaic 产品图标',
      ),
    );
  }
}
