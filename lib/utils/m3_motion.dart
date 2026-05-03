import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Material 3 Expressive Motion Constants
///
/// Centralized motion tokens following the Material Design 3 motion spec.
/// See: https://m3.material.io/styles/motion/easing-and-duration
/// See: https://m3.material.io/styles/motion/transitions/transition-patterns
class M3Motion {
  M3Motion._();

  // ─── Easing Curves (M3 Spec) ──────────────────────────────────────────

  /// Emphasized: For common, M3-styled animations that begin and end on screen.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Emphasized Decelerate: For M3-styled animations entering the screen.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized Accelerate: For M3-styled animations exiting the screen.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Standard: For utility-focused animations that begin and end on screen.
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Standard Decelerate: For utility-focused animations entering the screen.
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);

  /// Standard Accelerate: For utility-focused animations exiting the screen.
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  // ─── Duration Tokens (M3 Spec) ────────────────────────────────────────

  static const Duration durationShort1 = Duration(milliseconds: 50);
  static const Duration durationShort2 = Duration(milliseconds: 100);
  static const Duration durationShort3 = Duration(milliseconds: 150);
  static const Duration durationShort4 = Duration(milliseconds: 200);
  static const Duration durationMedium1 = Duration(milliseconds: 250);
  static const Duration durationMedium2 = Duration(milliseconds: 300);
  static const Duration durationMedium3 = Duration(milliseconds: 350);
  static const Duration durationMedium4 = Duration(milliseconds: 400);
  static const Duration durationLong1 = Duration(milliseconds: 450);
  static const Duration durationLong2 = Duration(milliseconds: 500);
  static const Duration durationLong3 = Duration(milliseconds: 550);
  static const Duration durationLong4 = Duration(milliseconds: 600);
  static const Duration durationExtraLong1 = Duration(milliseconds: 700);
  static const Duration durationExtraLong2 = Duration(milliseconds: 800);
  static const Duration durationExtraLong3 = Duration(milliseconds: 900);
  static const Duration durationExtraLong4 = Duration(milliseconds: 1000);

  // ─── Spring Tokens (M3 Expressive Spec) ───────────────────────────────

  /// Fast spatial: For small component animations (switches, buttons).
  static const double springFastSpatialDamping = 0.9;
  static const double springFastSpatialStiffness = 1400.0;

  /// Fast effects: For small component effects (color, opacity).
  static const double springFastEffectsDamping = 1.0;
  static const double springFastEffectsStiffness = 3800.0;

  /// Default spatial: For medium component animations (sheets, drawers).
  static const double springDefaultSpatialDamping = 0.9;
  static const double springDefaultSpatialStiffness = 700.0;

  /// Default effects: For medium component effects (color, opacity).
  static const double springDefaultEffectsDamping = 1.0;
  static const double springDefaultEffectsStiffness = 1600.0;

  /// Slow spatial: For full-screen animations and transitions.
  static const double springSlowSpatialDamping = 0.9;
  static const double springSlowSpatialStiffness = 300.0;

  /// Slow effects: For full-screen animation effects (color, opacity).
  static const double springSlowEffectsDamping = 1.0;
  static const double springSlowEffectsStiffness = 800.0;

  // ─── Route Builders ───────────────────────────────────────────────────

  /// Creates a Shared Axis route transition (Z-axis / scaled by default).
  /// Use for parent → child navigation (settings → sub-screen, list → detail).
  static PageRouteBuilder<T> sharedAxisRoute<T>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
    Duration duration = durationMedium4,
    Duration reverseDuration = durationMedium3,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  /// Creates a Fade Through route transition.
  /// Use for top-level navigation between unrelated destinations.
  static PageRouteBuilder<T> fadeThroughRoute<T>(
    Widget page, {
    Duration duration = durationMedium2,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }
}
