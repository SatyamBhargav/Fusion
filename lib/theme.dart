import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fusion colour tokens — lifted 1:1 from the design canvas, with a dark
/// counterpart. Read them from the theme with `context.fc`.
@immutable
class FC extends ThemeExtension<FC> {
  const FC({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.panel,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.icon,
    required this.line,
    required this.divider,
    required this.violet,
    required this.violetDeep,
    required this.violetText,
    required this.violetTint,
    required this.lavender,
    required this.lime,
    required this.onLime,
    required this.limeTint,
    required this.limeInk,
    required this.limeText,
    required this.onViolet,
    required this.onVioletGlass,
    required this.danger,
    required this.dangerTint,
    required this.fair,
    required this.fairText,
    required this.segBg,
    required this.switchOff,
    required this.checkOff,
    required this.success,
    required this.scrim,
  });

  /// Page background.
  final Color bg;

  /// Cards and inline tiles.
  final Color surface;

  /// Floating layers: nav bar, sheets, segmented pill.
  final Color raised;

  /// Dark slabs that carry white content (toasts, chips).
  final Color panel;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color icon;
  final Color line;
  final Color divider;
  final Color violet;
  final Color violetDeep;
  final Color violetText;
  final Color violetTint;
  final Color lavender;
  final Color lime;

  /// Text and icons on lime — dark in both themes.
  final Color onLime;
  final Color limeTint;
  final Color limeInk;
  final Color limeText;
  final Color onViolet;
  final Color onVioletGlass;
  final Color danger;
  final Color dangerTint;
  final Color fair;
  final Color fairText;
  final Color segBg;
  final Color switchOff;
  final Color checkOff;
  final Color success;
  final Color scrim;

  static const light = FC(
    bg: Color(0xFFF5F4FA),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    panel: Color(0xFF16142B),
    ink: Color(0xFF16142B),
    ink2: Color(0xFF3A3752),
    muted: Color(0xFF5F5C76),
    icon: Color(0xFF7C7894),
    line: Color(0xFFE6E3F1),
    divider: Color(0xFFEEECF5),
    violet: Color(0xFF5B47F5),
    violetDeep: Color(0xFF3B2BC4),
    violetText: Color(0xFF4A38D8),
    violetTint: Color(0xFFECE9FF),
    lavender: Color(0xFFE7E3FF),
    lime: Color(0xFFD7F75B),
    onLime: Color(0xFF16142B),
    limeTint: Color(0xFFEEFBC5),
    limeInk: Color(0xFF3D4A0B),
    limeText: Color(0xFF2E3809),
    onViolet: Color(0xFFF1EFFF),
    onVioletGlass: Color(0x29FFFFFF),
    danger: Color(0xFFC8303A),
    dangerTint: Color(0xFFFDE7E8),
    fair: Color(0xFFE08A00),
    fairText: Color(0xFF9A5200),
    segBg: Color(0xFFE9E7F2),
    switchOff: Color(0xFFDCD9E8),
    checkOff: Color(0xFFC9C5DA),
    success: Color(0xFF3E7A12),
    scrim: Color(0x8C16142B),
  );

  static const dark = FC(
    bg: Color(0xFF0F0E1A),
    surface: Color(0xFF1A1929),
    raised: Color(0xFF242238),
    panel: Color(0xFF363360),
    ink: Color(0xFFF1EFFF),
    ink2: Color(0xFFCBC7E0),
    muted: Color(0xFF9D99B6),
    icon: Color(0xFF8A86A6),
    line: Color(0xFF2E2C44),
    divider: Color(0xFF25233A),
    violet: Color(0xFF6E5BFF),
    violetDeep: Color(0xFFB3A8FF),
    violetText: Color(0xFFA99DFF),
    violetTint: Color(0xFF26214D),
    lavender: Color(0xFF2C2659),
    lime: Color(0xFFD7F75B),
    onLime: Color(0xFF16142B),
    limeTint: Color(0xFF222A0E),
    limeInk: Color(0xFFC9E86A),
    limeText: Color(0xFFDDEFA6),
    onViolet: Color(0xFFF1EFFF),
    onVioletGlass: Color(0x29FFFFFF),
    danger: Color(0xFFEF5A63),
    dangerTint: Color(0xFF3A1A20),
    fair: Color(0xFFF0A030),
    fairText: Color(0xFFF5B860),
    segBg: Color(0xFF13121F),
    switchOff: Color(0xFF3A3854),
    checkOff: Color(0xFF4A4766),
    success: Color(0xFF7CC44A),
    scrim: Color(0xB3000000),
  );

  /// Palettes are fixed; there are no per-token overrides.
  @override
  FC copyWith() => this;

  @override
  FC lerp(FC? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return FC(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      raised: l(raised, other.raised),
      panel: l(panel, other.panel),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      muted: l(muted, other.muted),
      icon: l(icon, other.icon),
      line: l(line, other.line),
      divider: l(divider, other.divider),
      violet: l(violet, other.violet),
      violetDeep: l(violetDeep, other.violetDeep),
      violetText: l(violetText, other.violetText),
      violetTint: l(violetTint, other.violetTint),
      lavender: l(lavender, other.lavender),
      lime: l(lime, other.lime),
      onLime: l(onLime, other.onLime),
      limeTint: l(limeTint, other.limeTint),
      limeInk: l(limeInk, other.limeInk),
      limeText: l(limeText, other.limeText),
      onViolet: l(onViolet, other.onViolet),
      onVioletGlass: l(onVioletGlass, other.onVioletGlass),
      danger: l(danger, other.danger),
      dangerTint: l(dangerTint, other.dangerTint),
      fair: l(fair, other.fair),
      fairText: l(fairText, other.fairText),
      segBg: l(segBg, other.segBg),
      switchOff: l(switchOff, other.switchOff),
      checkOff: l(checkOff, other.checkOff),
      success: l(success, other.success),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension FusionColorsX on BuildContext {
  FC get fc => Theme.of(this).extension<FC>()!;
}

/// Pastel tile palettes used for site monograms: (background, letter).
const List<(Color, Color)> tilePalettes = [
  (Color(0xFFE7E3FF), Color(0xFF3B2BC4)),
  (Color(0xFFFFE6DA), Color(0xFF8A3A17)),
  (Color(0xFFDDF5EA), Color(0xFF1F5E43)),
  (Color(0xFFDCEFFF), Color(0xFF1D4F7A)),
  (Color(0xFFEEFBC5), Color(0xFF3D4A0B)),
];

(Color, Color) paletteFor(String text) {
  final key = text.trim().toLowerCase();
  if (key.isEmpty) return tilePalettes.first;
  final sum = key.codeUnits.fold<int>(0, (a, b) => a + b);
  return tilePalettes[sum % tilePalettes.length];
}

/// Typography: Bricolage Grotesque (display), DM Sans (body), DM Mono (secrets).
/// A null [color] inherits the theme's ink via [DefaultTextStyle].
class FT {
  static TextStyle display(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w800,
    double height = 1.05,
    double spacing = -0.8,
  }) {
    try {
      return GoogleFonts.getFont(
        'Bricolage Grotesque',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );
    } catch (_) {
      return GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );
    }
  }

  static TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? spacing,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );

  static TextStyle mono(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? spacing,
    double? height,
  }) => GoogleFonts.dmMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );

  static TextStyle label({Color? color}) =>
      body(13, weight: FontWeight.w700, color: color);

  static TextStyle eyebrow({Color? color}) =>
      body(12, weight: FontWeight.w700, color: color, spacing: 0.6);
}

ThemeData buildFusionTheme(FC fc, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: fc.violet,
      brightness: brightness,
      primary: fc.violet,
      surface: fc.bg,
    ),
    scaffoldBackgroundColor: fc.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: fc.ink, displayColor: fc.ink),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: fc.violet,
      selectionColor: fc.violetTint,
      selectionHandleColor: fc.violet,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: fc.violet),
    snackBarTheme: SnackBarThemeData(backgroundColor: fc.panel),
    extensions: [fc],
  );
}

const darkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

const lightStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// Status bar for screens drawn on the page background.
SystemUiOverlayStyle statusBarFor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? lightStatusBar
    : darkStatusBar;

/// Closes [route] even if something (like the app lock) was pushed over it
/// while it was busy: pops when on top, otherwise removes just that route.
void closeRoute<T>(NavigatorState nav, Route<T> route, [T? result]) {
  if (route.isCurrent) {
    nav.pop(result);
  } else if (route.isActive) {
    nav.removeRoute(route, result);
  }
}

/// The house page transition: a short slide + fade.
Route<T> fusionRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
