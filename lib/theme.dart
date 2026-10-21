import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fusion colour tokens — lifted 1:1 from the design canvas.
class FC {
  static const bg = Color(0xFFF5F4FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF16142B);
  static const ink2 = Color(0xFF3A3752);
  static const muted = Color(0xFF5F5C76);
  static const icon = Color(0xFF7C7894);
  static const line = Color(0xFFE6E3F1);
  static const divider = Color(0xFFEEECF5);
  static const violet = Color(0xFF5B47F5);
  static const violetDeep = Color(0xFF3B2BC4);
  static const violetText = Color(0xFF4A38D8);
  static const violetTint = Color(0xFFECE9FF);
  static const lavender = Color(0xFFE7E3FF);
  static const lime = Color(0xFFD7F75B);
  static const limeTint = Color(0xFFEEFBC5);
  static const limeInk = Color(0xFF3D4A0B);
  static const limeText = Color(0xFF2E3809);
  static const onViolet = Color(0xFFF1EFFF);
  static const onVioletGlass = Color(0x29FFFFFF);
  static const danger = Color(0xFFC8303A);
  static const dangerTint = Color(0xFFFDE7E8);
  static const fair = Color(0xFFE08A00);
  static const fairText = Color(0xFF9A5200);
  static const segBg = Color(0xFFE9E7F2);
  static const switchOff = Color(0xFFDCD9E8);
  static const checkOff = Color(0xFFC9C5DA);
  static const success = Color(0xFF3E7A12);
  static const scrim = Color(0x8C16142B);
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
class FT {
  static TextStyle display(
    double size, {
    Color color = FC.ink,
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
    Color color = FC.ink,
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
    Color color = FC.ink,
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

  static TextStyle label() => body(13, weight: FontWeight.w700, color: FC.ink2);

  static TextStyle eyebrow({Color color = FC.muted}) =>
      body(12, weight: FontWeight.w700, color: color, spacing: 0.6);
}

ThemeData buildFusionTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FC.violet,
      primary: FC.violet,
      surface: FC.bg,
    ),
    scaffoldBackgroundColor: FC.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: FC.ink, displayColor: FC.ink),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: FC.violet,
      selectionColor: FC.violetTint,
      selectionHandleColor: FC.violet,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: FC.violet),
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
