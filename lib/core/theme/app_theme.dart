import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.paper2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.inkMute,
    required this.rule,
    required this.ruleSoft,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.positive,
    required this.negative,
    required this.neutral,
  });

  final Color paper;
  final Color paper2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color inkMute;
  final Color rule;
  final Color ruleSoft;
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;
  final Color positive;
  final Color negative;
  final Color neutral;

  static const light = AppColors(
    paper: Color(0xFFFFFFFF),
    paper2: Color(0xFFF4F7FC),
    ink: Color(0xFF11151C),
    ink2: Color(0xFF2B3340),
    ink3: Color(0xFF5B6373),
    inkMute: Color(0xFF8A92A1),
    rule: Color(0xFFD4D8E0),
    ruleSoft: Color(0xFFE7EAEF),
    accent: Color(0xFF0B4FD9),
    accentDeep: Color(0xFF0A44BD),
    accentSoft: Color(0xFFE8EFFF),
    positive: Color(0xFF3A6B3A),
    negative: Color(0xFFB8341F),
    neutral: Color(0xFF8A7C5A),
  );

  static const dark = AppColors(
    paper: Color(0xFF141B26),
    paper2: Color(0xFF0C1118),
    ink: Color(0xFFEDF1F8),
    ink2: Color(0xFFC6CEDA),
    ink3: Color(0xFF9FABBC),
    inkMute: Color(0xFF7E8A9B),
    rule: Color(0xFF303A49),
    ruleSoft: Color(0xFF242E3B),
    accent: Color(0xFF7CA3FF),
    accentDeep: Color(0xFF9DBAFF),
    accentSoft: Color(0xFF1E2C48),
    positive: Color(0xFF8AD08A),
    negative: Color(0xFFF1988A),
    neutral: Color(0xFFD9C791),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? paper,
    Color? paper2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? inkMute,
    Color? rule,
    Color? ruleSoft,
    Color? accent,
    Color? accentDeep,
    Color? accentSoft,
    Color? positive,
    Color? negative,
    Color? neutral,
  }) => AppColors(
    paper: paper ?? this.paper,
    paper2: paper2 ?? this.paper2,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    inkMute: inkMute ?? this.inkMute,
    rule: rule ?? this.rule,
    ruleSoft: ruleSoft ?? this.ruleSoft,
    accent: accent ?? this.accent,
    accentDeep: accentDeep ?? this.accentDeep,
    accentSoft: accentSoft ?? this.accentSoft,
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    neutral: neutral ?? this.neutral,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      inkMute: Color.lerp(inkMute, other.inkMute, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ruleSoft: Color.lerp(ruleSoft, other.ruleSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => AppColors.of(this);
}

class AppTheme {
  AppTheme._();

  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const amountFeatures = [FontFeature.tabularFigures()];

  static ThemeData light() => _theme(AppColors.light, Brightness.light);

  static ThemeData dark() => _theme(AppColors.dark, Brightness.dark);

  static ThemeData _theme(AppColors colors, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B4FD9),
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          onPrimary: brightness == Brightness.dark
              ? const Color(0xFF07122B)
              : Colors.white,
          secondary: colors.accentDeep,
          surface: colors.paper,
          onSurface: colors.ink,
          error: colors.negative,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.paper2,
      extensions: [colors],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: colors.ruleSoft),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.ruleSoft,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.paper,
        selectedColor: colors.accentSoft,
        side: BorderSide(color: colors.rule),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.ink2,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: colors.inkMute, fontSize: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.rule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
        contentTextStyle: TextStyle(color: colors.paper, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.accent
                : colors.ink3,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colors.rule)),
        ),
      ),
    );
  }

  static TextStyle cardTitle(BuildContext context, {double size = 15}) =>
      TextStyle(
        fontSize: size,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: context.colors.ink,
      );

  static TextStyle meta(BuildContext context, {double size = 12.5}) =>
      TextStyle(fontSize: size, height: 1.35, color: context.colors.ink3);
}
