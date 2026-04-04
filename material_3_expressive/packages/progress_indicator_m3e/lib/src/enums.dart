/// Circular sizes driven by outer diameter.
enum CircularProgressM3ESize { sm, md, lg, xl }

extension CircularM3ESizeExtension on CircularProgressM3ESize {
  double get diameterWavy {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 52.0;
      case CircularProgressM3ESize.md:
        return 68.0;
      case CircularProgressM3ESize.lg:
        return 84.0;
      case CircularProgressM3ESize.xl:
        return 110.0;
    }
  }

  double get diameterFlat {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 40.0;
      case CircularProgressM3ESize.md:
        return 44.0;
      case CircularProgressM3ESize.lg:
        return 64.0;
      case CircularProgressM3ESize.xl:
        return 88.0;
    }
  }

  double get defaultStrokeWidth {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 4.0;
      case CircularProgressM3ESize.md:
        return 6.0;
      case CircularProgressM3ESize.lg:
        return 10.0;
      case CircularProgressM3ESize.xl:
        return 12.0;
    }
  }

  double get defaultWaveAmplitude {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 4.0;
      case CircularProgressM3ESize.md:
        return 4.0;
      case CircularProgressM3ESize.lg:
        return 5.0;
      case CircularProgressM3ESize.xl:
        return 6.0;
    }
  }

  double get defaultWaveLength {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 15.0;
      case CircularProgressM3ESize.md:
        return 15.0;
      case CircularProgressM3ESize.lg:
        return 20.0;
      case CircularProgressM3ESize.xl:
        return 24.0;
    }
  }

  /// Default animation speed multiplier per size.
  /// Higher = faster wave animation. Base duration is 3000ms / speed.
  double get defaultSpeed {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 2.0;
      case CircularProgressM3ESize.md:
        return 3.0;
      case CircularProgressM3ESize.lg:
        return 3.0;
      case CircularProgressM3ESize.xl:
        return 4.0;
    }
  }

  /// Default gap (in dp) between the active wave and the inactive track.
  double get defaultGap {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 4.0;
      case CircularProgressM3ESize.md:
        return 6.0;
      case CircularProgressM3ESize.lg:
        return 8.0;
      case CircularProgressM3ESize.xl:
        return 10.0;
    }
  }

  /// Default animation speed multiplier for indeterminate state.
  double defaultIndeterminateSpeed(ProgressM3EShape shape) {
    return shape == ProgressM3EShape.wavy ? 0.7 : 0.5;
  }

  /// Default stroke width for indeterminate state.
  double get defaultIndeterminateStrokeWidth {
    switch (this) {
      case CircularProgressM3ESize.sm:
        return 4.0;
      case CircularProgressM3ESize.md:
        return 6.0;
      case CircularProgressM3ESize.lg:
        return 8.0;
      case CircularProgressM3ESize.xl:
        return 8.0;
    }
  }
}

/// Linear sizes and shapes
enum LinearProgressM3ESize { sm, md }

enum ProgressM3EShape { flat, wavy }
