import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/motion.dart';

/// Shown until the stored account has been read.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBar,
      child: Scaffold(
        backgroundColor: context.fc.violet,
        body: const Center(
          child: PopIn(child: FusionLogo(size: 80, left: Colors.white)),
        ),
      ),
    );
  }
}
