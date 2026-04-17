// ไฟล์: lib/core/theme.dart
import 'package:flutter/material.dart';

// ════════════════════════════════════════════
//  APP COLORS
// ════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ─── Primary ───
  static const Color primary        = Color(0xFF0056B3);
  static const Color primaryLight   = Color(0xFF4A88C7);
  static const Color primarySurface = Color(0xFFE8F0FE);

  // ─── Status ───
  static const Color success        = Color(0xFF28A745);
  static const Color successLight   = Color(0xFFD4EDDA);
  static const Color danger         = Color(0xFFDC3545);
  static const Color dangerLight    = Color(0xFFF8D7DA);
  static const Color warning        = Color(0xFFFFC107);
  static const Color info           = Color(0xFF17A2B8);

  // ─── Neutral ───
  static const Color dark           = Color(0xFF0F172A);
  static const Color textPrimary    = Color(0xFF212529);
  static const Color textSecondary  = Color(0xFF495057);
  static const Color textMuted      = Color(0xFF6C757D);
  static const Color border         = Color(0xFFDEE2E6);
  static const Color surface        = Color(0xFFF8F9FA);
  static const Color background     = Color(0xFFF4F6F8);

  // ─── Sidebar ───
  static const Color sidebarBg      = Color(0xFF1A1D23);
  static const Color sidebarText    = Colors.white70;
  static const Color sidebarActive  = Colors.white;

  // ─── Badge ───
  static Color availableBg    = Colors.green.shade50;
  static Color availableBorder= Colors.green.shade200;
  static Color availableText  = Colors.green.shade700;
  static Color inUseBg        = Colors.red.shade50;
  static Color inUseBorder    = Colors.red.shade200;
  static Color inUseText      = Colors.red.shade700;
}

// ════════════════════════════════════════════
//  TEXT STYLES
// ════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark);

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark);

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark);

  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary);

  static const TextStyle tableHeader = TextStyle(
    fontSize: 11, fontWeight: FontWeight.bold);

  static const TextStyle body = TextStyle(fontSize: 14, color: AppColors.textPrimary);

  static const TextStyle bodySmall = TextStyle(fontSize: 13, color: AppColors.textSecondary);

  static const TextStyle hint = TextStyle(color: Color(0xFFADB5BD));
}

// ════════════════════════════════════════════
//  INPUT DECORATIONS
// ════════════════════════════════════════════

class AppInputDecoration {
  AppInputDecoration._();

  static InputDecoration standard({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: filled,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  static InputDecoration search({required String hint}) {
    return standard(
      hint: hint,
      prefix: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
    ).copyWith(fillColor: AppColors.surface);
  }

  static InputDecoration dense({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}

// ════════════════════════════════════════════
//  BUTTON STYLES
// ════════════════════════════════════════════

class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle primary({EdgeInsets? padding}) => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    elevation: 0,
  );

  static ButtonStyle success({EdgeInsets? padding}) => ElevatedButton.styleFrom(
    backgroundColor: AppColors.success,
    foregroundColor: Colors.white,
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    elevation: 0,
  );

  static ButtonStyle danger({EdgeInsets? padding}) => ElevatedButton.styleFrom(
    backgroundColor: AppColors.danger,
    foregroundColor: Colors.white,
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    elevation: 0,
  );

  static ButtonStyle info({EdgeInsets? padding}) => ElevatedButton.styleFrom(
    backgroundColor: AppColors.info,
    foregroundColor: Colors.white,
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    elevation: 0,
  );

  static ButtonStyle outlined({EdgeInsets? padding}) => OutlinedButton.styleFrom(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );
}

// ════════════════════════════════════════════
//  REUSABLE WIDGETS
// ════════════════════════════════════════════

class AppWidgets {
  AppWidgets._();

  /// Status badge: available / in_use
  static Widget statusBadge(bool inUse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: inUse ? AppColors.inUseBg    : AppColors.availableBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: inUse ? AppColors.inUseBorder : AppColors.availableBorder)),
      child: Text(inUse ? 'In Use' : 'Available',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
          color: inUse ? AppColors.inUseText : AppColors.availableText)),
    );
  }

  /// Mini chip badge
  static Widget miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  /// Section card container
  static Widget card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6, offset: const Offset(0, 2))]),
      child: child,
    );
  }

  /// Empty state hint
  static Widget emptyHint(String text, {IconData icon = Icons.inbox_outlined}) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 40, color: Colors.grey.shade300),
      const SizedBox(height: 10),
      Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    ]));
  }

  /// Table header container
  static Widget tableHeader({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
      child: Row(children: children),
    );
  }

  /// Form label + field wrapper
  static Widget formField({required String label, required Widget field}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      field,
    ]);
  }
}

// ════════════════════════════════════════════
//  APP THEME
// ════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.background,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.dark,
      elevation: 0,
    ),
  );
}

// ════════════════════════════════════════════
//  APP SNACKBAR — floating popup
// ════════════════════════════════════════════

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    Color? color,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final bgColor = color ?? AppColors.dark;

    // เลือก icon อัตโนมัติตามสี
    IconData resolvedIcon = icon ?? _iconForColor(bgColor);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior:        SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation:       0,
        duration:        duration,
        margin: const EdgeInsets.only(
          bottom: 24, left: 24, right: 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:        bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset:     const Offset(0, 4)),
            ]),
          child: Row(children: [
            Icon(resolvedIcon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   14,
                fontWeight: FontWeight.w500))),
          ]),
        ),
      ));
  }

  static void success(BuildContext context, String message) =>
    show(context, message, color: AppColors.success, icon: Icons.check_circle_outline);

  static void error(BuildContext context, String message) =>
    show(context, message, color: AppColors.danger, icon: Icons.error_outline);

  static void warning(BuildContext context, String message) =>
    show(context, message, color: const Color(0xFFB45309), icon: Icons.warning_amber_outlined);

  static void info(BuildContext context, String message) =>
    show(context, message, color: AppColors.info, icon: Icons.info_outline);

  static IconData _iconForColor(Color color) {
    if (color == AppColors.success) return Icons.check_circle_outline;
    if (color == AppColors.danger)  return Icons.error_outline;
    if (color == AppColors.warning) return Icons.warning_amber_outlined;
    if (color == AppColors.info)    return Icons.info_outline;
    return Icons.notifications_outlined;
  }
}