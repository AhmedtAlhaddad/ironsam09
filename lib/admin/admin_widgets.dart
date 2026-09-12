import 'package:flutter/material.dart';

abstract final class AdminColors {
  static const background = Color(0xFFF6F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1B1B18);
  static const textSecondary = Color(0xFF77736D);
  static const border = Color(0xFFE4E1DC);
  static const primary = Color(0xFF1B1B18);
  static const accent = Color(0xFFA85638);
  static const accentSoft = Color(0xFFF4E8E2);
  static const success = Color(0xFF2F7D5A);
  static const successSoft = Color(0xFFEAF4EF);
  static const danger = Color(0xFFC44B32);
  static const dangerSoft = Color(0xFFFBEDE9);
  static const sidebar = Color(0xFF171714);
  static const sidebarText = Color(0xFFB8B5AF);
  static const sidebarSelected = Color(0xFF3A2821);
}

ThemeData adminTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: AdminColors.background,
  colorScheme: base.colorScheme.copyWith(
    primary: AdminColors.primary,
    onPrimary: Colors.white,
    secondary: AdminColors.accent,
    onSecondary: Colors.white,
    error: AdminColors.danger,
    onError: Colors.white,
    surface: AdminColors.surface,
    onSurface: AdminColors.textPrimary,
    outline: AdminColors.border,
  ),
  appBarTheme: base.appBarTheme.copyWith(
    backgroundColor: AdminColors.background,
    foregroundColor: AdminColors.textPrimary,
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(color: AdminColors.border),
  dialogTheme: DialogThemeData(
    backgroundColor: AdminColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 18,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AdminColors.border),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AdminColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: const TextStyle(color: AdminColors.textSecondary),
    hintStyle: const TextStyle(color: AdminColors.textSecondary),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminColors.accent, width: 1.4),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminColors.danger),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminColors.danger, width: 1.4),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AdminColors.textPrimary,
      side: const BorderSide(color: AdminColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AdminColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AdminColors.primary,
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
);

InputDecoration adminRtlInputDecoration(InputDecoration decoration) =>
    decoration.copyWith(hintTextDirection: TextDirection.rtl);

Widget adminRtlDropdownItem(String label) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: Text(
    label,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
  ),
);

class AdminDialogHeader extends StatelessWidget {
  const AdminDialogHeader({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ),
      IconButton(
        tooltip: 'إغلاق',
        style: IconButton.styleFrom(
          foregroundColor: AdminColors.textSecondary,
          hoverColor: AdminColors.background,
        ),
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close),
      ),
    ],
  );
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.framed = true,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final bool framed;

  @override
  Widget build(BuildContext context) => Container(
    decoration: framed
        ? BoxDecoration(
            color: AdminColors.surface,
            border: Border.all(color: AdminColors.border),
            borderRadius: BorderRadius.circular(16),
          )
        : null,
    padding: framed ? const EdgeInsets.all(20) : EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AdminColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    required this.label,
    this.tone = AdminStatusTone.neutral,
    super.key,
  });
  final String label;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AdminStatusTone.good => AdminColors.success,
      AdminStatusTone.warning => AdminColors.accent,
      AdminStatusTone.danger => AdminColors.danger,
      AdminStatusTone.neutral => AdminColors.textSecondary,
    };
    final background = switch (tone) {
      AdminStatusTone.good => AdminColors.successSoft,
      AdminStatusTone.warning => AdminColors.accentSoft,
      AdminStatusTone.danger => AdminColors.dangerSoft,
      AdminStatusTone.neutral => AdminColors.background,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum AdminStatusTone { good, warning, danger, neutral }

class StockStepper extends StatelessWidget {
  const StockStepper({
    required this.value,
    required this.onChanged,
    this.compact = false,
    super.key,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 42.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'إنقاص المخزون',
          onPressed: value == 0 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove),
          constraints: BoxConstraints.tightFor(width: size, height: size),
          padding: EdgeInsets.zero,
        ),
        Container(
          width: compact ? 42 : 52,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: 'زيادة المخزون',
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
          constraints: BoxConstraints.tightFor(width: size, height: size),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

Future<bool> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: AdminDialogHeader(title: title),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmLabel == 'حذف' || confirmLabel == 'إزالة'
                  ? AdminColors.danger
                  : AdminColors.primary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

void showAdminMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: error ? AdminColors.danger : AdminColors.primary,
      content: Text(message),
    ),
  );
}
