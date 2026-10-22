import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// The exact stroke icons from the design (24×24 viewBox).
class FIcons {
  static const mail =
      '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M3 7l9 6 9-6"/>';
  static const lock =
      '<rect x="4" y="10" width="16" height="11" rx="3"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>';
  static const eye =
      '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>';
  static const eyeOff =
      '<path d="M3 3l18 18"/><path d="M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.1 3.9"/><path d="M6.6 6.6C3.9 8.3 2 12 2 12s3.5 7 10 7a9.7 9.7 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>';
  static const user =
      '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>';
  static const users =
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c0-3.5 3-5.5 6.5-5.5s6.5 2 6.5 5.5"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7"/><path d="M18 14.8c2.2.6 3.5 2.3 3.5 5.2"/>';
  static const back = '<path d="M15 18l-6-6 6-6"/>';
  static const chevronRight = '<path d="M9 18l6-6-6-6"/>';
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>';
  static const star =
      '<path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1.1 6.2L12 17.3 6.4 20.2l1.1-6.2L3 9.6l6.2-.9z"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const copy =
      '<rect x="9" y="9" width="12" height="12" rx="3"/><path d="M5 15V6a2 2 0 0 1 2-2h8"/>';
  static const refresh =
      '<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>';
  static const pencil =
      '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M14 6l4 4"/>';
  static const trash =
      '<path d="M4 7h16"/><path d="M10 11v6M14 11v6"/><path d="M6 7l1 13h10l1-13"/><path d="M9 7V4h6v3"/>';
  static const key =
      '<circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M17 6l3 3M15 8l2 2"/>';
  static const shield =
      '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/>';
  static const shieldCheck =
      '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>';
  static const check = '<path d="M5 12l5 5 9-10"/>';
  static const sparkle =
      '<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M6 18l2.5-2.5M15.5 8.5L18 6"/>';
  static const external =
      '<path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/>';
  static const arrowRight = '<path d="M5 12h14M13 6l6 6-6 6"/>';
  static const sliders =
      '<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1"/><circle cx="15" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="18" r="2"/>';
  static const info =
      '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>';
  static const sun =
      '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>';
  static const moon =
      '<path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/>';
  static const contrast =
      '<circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18z" fill="#000000"/>';
  static const fingerprint =
      '<path d="M12 10a2 2 0 0 0-2 2c0 1-.1 2.5-.26 4"/><path d="M14 13.1c0 2.4 0 6.4-1 8.9"/><path d="M17.3 21c.1-.6.4-2.3.5-3"/><path d="M2 12a10 10 0 0 1 18-6"/><path d="M2 16h.01"/><path d="M21.8 16c.2-2 .1-5.4 0-6"/><path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/><path d="M8.65 22c.2-.66.45-1.3.57-2"/><path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>';
  static const faceId =
      '<path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><path d="M9 9h.01M15 9h.01"/>';
  static const backspace =
      '<path d="M9 5h11a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H9l-6-7z"/><path d="M12 9l6 6M18 9l-6 6"/>';
}

class FIcon extends StatelessWidget {
  const FIcon(
    this.paths, {
    super.key,
    this.size = 20,
    this.color,
    this.stroke = 2,
    this.filled = false,
  });

  final String paths;
  final double size;
  final Color? color;
  final double stroke;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? '#000000' : 'none'}" '
        'stroke="#000000" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">$paths</svg>';
    return ExcludeSemantics(
      child: SvgPicture.string(
        svg,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color ?? context.fc.ink, BlendMode.srcIn),
      ),
    );
  }
}
