import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// High-level Material motion family.
enum MotionSchemeType { expressive, standard }

/// Motion domain for a transition.
enum MotionDomain { spatial, effects }

/// Relative speed bucket used by Material motion tokens.
enum MotionSpeed { fast, medium, slow }

/// Behavior used when reduced motion is requested by accessibility settings.
enum ReducedMotionBehavior { instant, simplifiedSpring }

/// Immutable token describing one spring and its fallback curve.
@immutable
class MotionSpringToken {
  final double stiffness;
  final double dampingRatio;
  final double mass;
  final Cubic fallbackCurve;
  final Duration fallbackDuration;

  const MotionSpringToken({
    required this.stiffness,
    required this.dampingRatio,
    required this.fallbackCurve,
    required this.fallbackDuration,
    this.mass = 1.0,
  });

  SpringDescription toSpringDescription() {
    return SpringDescription.withDampingRatio(
      mass: mass,
      stiffness: stiffness,
      ratio: dampingRatio,
    );
  }

  MotionSpringToken lerp(MotionSpringToken other, double t) {
    return MotionSpringToken(
      stiffness: ui.lerpDouble(stiffness, other.stiffness, t) ?? stiffness,
      dampingRatio:
          ui.lerpDouble(dampingRatio, other.dampingRatio, t) ?? dampingRatio,
      mass: ui.lerpDouble(mass, other.mass, t) ?? mass,
      fallbackCurve: Cubic(
        ui.lerpDouble(fallbackCurve.a, other.fallbackCurve.a, t) ??
            fallbackCurve.a,
        ui.lerpDouble(fallbackCurve.b, other.fallbackCurve.b, t) ??
            fallbackCurve.b,
        ui.lerpDouble(fallbackCurve.c, other.fallbackCurve.c, t) ??
            fallbackCurve.c,
        ui.lerpDouble(fallbackCurve.d, other.fallbackCurve.d, t) ??
            fallbackCurve.d,
      ),
      fallbackDuration: Duration(
        milliseconds:
            ((fallbackDuration.inMilliseconds * (1.0 - t)) +
                    (other.fallbackDuration.inMilliseconds * t))
                .round(),
      ),
    );
  }
}

/// Full token set for a scheme.
@immutable
class MotionSchemeTokens {
  final MotionSpringToken spatialFast;
  final MotionSpringToken spatialDefault;
  final MotionSpringToken spatialSlow;
  final MotionSpringToken effectsFast;
  final MotionSpringToken effectsDefault;
  final MotionSpringToken effectsSlow;

  const MotionSchemeTokens({
    required this.spatialFast,
    required this.spatialDefault,
    required this.spatialSlow,
    required this.effectsFast,
    required this.effectsDefault,
    required this.effectsSlow,
  });

  MotionSpringToken token(MotionDomain domain, MotionSpeed speed) {
    switch (domain) {
      case MotionDomain.spatial:
        switch (speed) {
          case MotionSpeed.fast:
            return spatialFast;
          case MotionSpeed.medium:
            return spatialDefault;
          case MotionSpeed.slow:
            return spatialSlow;
        }
      case MotionDomain.effects:
        switch (speed) {
          case MotionSpeed.fast:
            return effectsFast;
          case MotionSpeed.medium:
            return effectsDefault;
          case MotionSpeed.slow:
            return effectsSlow;
        }
    }
  }

  MotionSchemeTokens lerp(MotionSchemeTokens other, double t) {
    return MotionSchemeTokens(
      spatialFast: spatialFast.lerp(other.spatialFast, t),
      spatialDefault: spatialDefault.lerp(other.spatialDefault, t),
      spatialSlow: spatialSlow.lerp(other.spatialSlow, t),
      effectsFast: effectsFast.lerp(other.effectsFast, t),
      effectsDefault: effectsDefault.lerp(other.effectsDefault, t),
      effectsSlow: effectsSlow.lerp(other.effectsSlow, t),
    );
  }
}

/// Canonical Material 3 token values.
class MaterialMotionPresets {
  MaterialMotionPresets._();

  static const MotionSchemeTokens expressive = MotionSchemeTokens(
    spatialFast: MotionSpringToken(
      stiffness: 800,
      dampingRatio: 0.45,
      fallbackCurve: Cubic(0.42, 1.67, 0.21, 0.90),
      fallbackDuration: Duration(milliseconds: 350),
    ),
    spatialDefault: MotionSpringToken(
      stiffness: 380,
      dampingRatio: 0.40,
      fallbackCurve: Cubic(0.38, 1.21, 0.22, 1.00),
      fallbackDuration: Duration(milliseconds: 500),
    ),
    spatialSlow: MotionSpringToken(
      stiffness: 200,
      dampingRatio: 0.35,
      fallbackCurve: Cubic(0.39, 1.29, 0.35, 0.98),
      fallbackDuration: Duration(milliseconds: 650),
    ),
    effectsFast: MotionSpringToken(
      stiffness: 3800,
      dampingRatio: 0.80,
      fallbackCurve: Cubic(0.31, 0.94, 0.34, 1.00),
      fallbackDuration: Duration(milliseconds: 150),
    ),
    effectsDefault: MotionSpringToken(
      stiffness: 1600,
      dampingRatio: 0.85,
      fallbackCurve: Cubic(0.34, 0.80, 0.34, 1.00),
      fallbackDuration: Duration(milliseconds: 200),
    ),
    effectsSlow: MotionSpringToken(
      stiffness: 800,
      dampingRatio: 0.90,
      fallbackCurve: Cubic(0.34, 0.88, 0.34, 1.00),
      fallbackDuration: Duration(milliseconds: 300),
    ),
  );

  static const MotionSchemeTokens standard = MotionSchemeTokens(
    spatialFast: MotionSpringToken(
      stiffness: 1400,
      dampingRatio: 0.9,
      fallbackCurve: Cubic(0.27, 1.06, 0.18, 1.00),
      fallbackDuration: Duration(milliseconds: 350),
    ),
    spatialDefault: MotionSpringToken(
      stiffness: 700,
      dampingRatio: 0.9,
      fallbackCurve: Cubic(0.27, 1.06, 0.18, 1.00),
      fallbackDuration: Duration(milliseconds: 500),
    ),
    spatialSlow: MotionSpringToken(
      stiffness: 300,
      dampingRatio: 0.9,
      fallbackCurve: Cubic(0.27, 1.06, 0.18, 1.00),
      fallbackDuration: Duration(milliseconds: 750),
    ),
    effectsFast: MotionSpringToken(
      stiffness: 3800,
      dampingRatio: 1.0,
      fallbackCurve: Cubic(0.31, 0.94, 0.34, 1.00),
      fallbackDuration: Duration(milliseconds: 150),
    ),
    effectsDefault: MotionSpringToken(
      stiffness: 1600,
      dampingRatio: 1.0,
      fallbackCurve: Cubic(0.34, 0.80, 0.34, 1.00),
      fallbackDuration: Duration(milliseconds: 200),
    ),
    effectsSlow: MotionSpringToken(
      stiffness: 800,
      dampingRatio: 1.0,
      fallbackCurve: Cubic(0.34, 0.88, 0.34, 1.00),
      fallbackDuration: Duration(milliseconds: 300),
    ),
  );
}

/// Runtime motion engine with velocity-handoff helpers.
@immutable
class MotionPhysicsEngine {
  final MotionSchemeTokens tokens;
  final bool useFallbackCurves;
  final bool reducedMotion;
  final ReducedMotionBehavior reducedMotionBehavior;

  const MotionPhysicsEngine({
    required this.tokens,
    this.useFallbackCurves = false,
    this.reducedMotion = false,
    this.reducedMotionBehavior = ReducedMotionBehavior.instant,
  });

  const MotionPhysicsEngine.expressive({
    this.useFallbackCurves = false,
    this.reducedMotion = false,
    this.reducedMotionBehavior = ReducedMotionBehavior.instant,
  }) : tokens = MaterialMotionPresets.expressive;

  const MotionPhysicsEngine.standard({
    this.useFallbackCurves = false,
    this.reducedMotion = false,
    this.reducedMotionBehavior = ReducedMotionBehavior.instant,
  }) : tokens = MaterialMotionPresets.standard;

  MotionSpringToken token(MotionDomain domain, MotionSpeed speed) {
    return tokens.token(domain, speed);
  }

  SpringDescription spring(MotionDomain domain, MotionSpeed speed) {
    return token(domain, speed).toSpringDescription();
  }

  Duration fallbackDuration(MotionDomain domain, MotionSpeed speed) {
    return token(domain, speed).fallbackDuration;
  }

  Curve fallbackCurve(MotionDomain domain, MotionSpeed speed) {
    return token(domain, speed).fallbackCurve;
  }

  SpringSimulation createSimulation({
    required AnimationController controller,
    required double target,
    required MotionDomain domain,
    required MotionSpeed speed,
    double? velocity,
  }) {
    return SpringSimulation(
      spring(domain, speed),
      controller.value,
      target,
      velocity ?? controller.velocity,
      snapToEnd: true,
    );
  }

  TickerFuture animate(
    AnimationController controller, {
    required double target,
    required MotionDomain domain,
    required MotionSpeed speed,
    double? velocity,
  }) {
    if (reducedMotion &&
        reducedMotionBehavior == ReducedMotionBehavior.instant) {
      controller.value = target;
      return controller.animateTo(target, duration: Duration.zero);
    }

    if (reducedMotion &&
        reducedMotionBehavior == ReducedMotionBehavior.simplifiedSpring) {
      final MotionSpeed reducedSpeed = speed == MotionSpeed.slow
          ? MotionSpeed.medium
          : speed;
      final SpringSimulation reducedSimulation = SpringSimulation(
        MaterialMotionPresets.standard
            .token(domain, reducedSpeed)
            .toSpringDescription(),
        controller.value,
        target,
        velocity ?? controller.velocity,
        snapToEnd: true,
      );
      return controller.animateWith(reducedSimulation);
    }

    if (useFallbackCurves) {
      return controller.animateTo(
        target,
        duration: fallbackDuration(domain, speed),
        curve: fallbackCurve(domain, speed),
      );
    }

    final SpringSimulation simulation = createSimulation(
      controller: controller,
      target: target,
      domain: domain,
      speed: speed,
      velocity: velocity,
    );
    return controller.animateWith(simulation);
  }

  MotionPhysicsEngine copyWith({
    MotionSchemeTokens? tokens,
    bool? useFallbackCurves,
    bool? reducedMotion,
    ReducedMotionBehavior? reducedMotionBehavior,
  }) {
    return MotionPhysicsEngine(
      tokens: tokens ?? this.tokens,
      useFallbackCurves: useFallbackCurves ?? this.useFallbackCurves,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      reducedMotionBehavior:
          reducedMotionBehavior ?? this.reducedMotionBehavior,
    );
  }
}

/// Theme-level motion configuration similar to MaterialTheme.motionScheme.
@immutable
class MotionSchemeExtension extends ThemeExtension<MotionSchemeExtension> {
  final MotionSchemeType scheme;
  final bool useFallbackCurves;
  final ReducedMotionBehavior reducedMotionBehavior;

  const MotionSchemeExtension({
    this.scheme = MotionSchemeType.expressive,
    this.useFallbackCurves = false,
    this.reducedMotionBehavior = ReducedMotionBehavior.instant,
  });

  MotionPhysicsEngine resolve({required bool reducedMotion}) {
    final MotionPhysicsEngine base = scheme == MotionSchemeType.expressive
        ? MotionPhysicsEngine.expressive(
            useFallbackCurves: useFallbackCurves,
            reducedMotion: reducedMotion,
            reducedMotionBehavior: reducedMotionBehavior,
          )
        : MotionPhysicsEngine.standard(
            useFallbackCurves: useFallbackCurves,
            reducedMotion: reducedMotion,
            reducedMotionBehavior: reducedMotionBehavior,
          );
    return base;
  }

  @override
  MotionSchemeExtension copyWith({
    MotionSchemeType? scheme,
    bool? useFallbackCurves,
    ReducedMotionBehavior? reducedMotionBehavior,
  }) {
    return MotionSchemeExtension(
      scheme: scheme ?? this.scheme,
      useFallbackCurves: useFallbackCurves ?? this.useFallbackCurves,
      reducedMotionBehavior:
          reducedMotionBehavior ?? this.reducedMotionBehavior,
    );
  }

  @override
  MotionSchemeExtension lerp(
    ThemeExtension<MotionSchemeExtension>? other,
    double t,
  ) {
    if (other is! MotionSchemeExtension) {
      return this;
    }

    // Discrete values choose the nearest endpoint.
    return t < 0.5 ? this : other;
  }
}

extension MotionSchemeContext on BuildContext {
  MotionPhysicsEngine motionEngine() {
    final ThemeData theme = Theme.of(this);
    final MotionSchemeExtension extension =
        theme.extension<MotionSchemeExtension>() ??
        const MotionSchemeExtension();

    final bool reducedMotion =
        MediaQuery.maybeOf(this)?.disableAnimations ?? false;

    return extension.resolve(reducedMotion: reducedMotion);
  }
}
