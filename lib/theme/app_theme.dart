import 'package:flutter/material.dart';

import '../models/lost_item.dart';

/// App-wide Material 3 theme, seeded from IBA maroon.
abstract final class AppTheme {
  static const Color seed = Color(0xFF7B1E3A);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

/// Colours and icon for a status badge, tuned for light and dark mode.
class StatusStyle {
  const StatusStyle({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;

  static StatusStyle of(ItemStatus status, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (status) {
      case ItemStatus.lost:
        return StatusStyle(
          foreground: dark ? const Color(0xFFFFB59A) : const Color(0xFFC2410C),
          background: dark ? const Color(0xFF4A1E0E) : const Color(0xFFFFEDE3),
          icon: Icons.search_rounded,
        );
      case ItemStatus.found:
        return StatusStyle(
          foreground: dark ? const Color(0xFF7FDBB6) : const Color(0xFF0B7A5C),
          background: dark ? const Color(0xFF0F3A2D) : const Color(0xFFDDF5EC),
          icon: Icons.where_to_vote_rounded,
        );
      case ItemStatus.claimed:
        return StatusStyle(
          foreground: dark ? const Color(0xFFC2BAFF) : const Color(0xFF5B4FC4),
          background: dark ? const Color(0xFF2B2650) : const Color(0xFFEDEAFC),
          icon: Icons.verified_rounded,
        );
    }
  }
}

/// Picks an icon for an item from its category, with a few title keywords
/// for nicer matches (a bottle and an umbrella are both "Accessory").
IconData iconForItem({required String category, String title = ''}) {
  final t = title.toLowerCase();
  if (t.contains('bottle')) return Icons.water_drop_rounded;
  if (t.contains('umbrella')) return Icons.umbrella_rounded;
  if (t.contains('charger')) return Icons.electrical_services_rounded;

  switch (category.toLowerCase()) {
    case 'bag':
      return Icons.backpack_rounded;
    case 'id card':
      return Icons.badge_rounded;
    case 'electronics':
      return Icons.devices_rounded;
    case 'keys':
      return Icons.key_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'clothing':
      return Icons.checkroom_rounded;
    case 'accessory':
      return Icons.sell_rounded;
    default:
      return Icons.category_rounded;
  }
}
