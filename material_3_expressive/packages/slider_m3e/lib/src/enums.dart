enum SliderM3ESize { small, medium, large }

enum SliderM3EEmphasis { primary, secondary, surface }

enum SliderM3EShapeFamily { round, square }

enum SliderM3EDensity { regular, compact }

enum SliderM3EShape { flat, wavy }

extension SliderM3ESizeExtension on SliderM3ESize {
  double get defaultGap {
    switch (this) {
      case SliderM3ESize.small:
        return 4.0;
      case SliderM3ESize.medium:
        return 6.0; // matching demo
      case SliderM3ESize.large:
        return 10.0;
    }
  }

  double get defaultWaveAmplitude {
    switch (this) {
      case SliderM3ESize.small:
        return 3.0;
      case SliderM3ESize.medium:
        return 5.0; // matching demo
      case SliderM3ESize.large:
        return 8.0;
    }
  }

  double get defaultWaveLength {
    switch (this) {
      case SliderM3ESize.small:
        return 20.0;
      case SliderM3ESize.medium:
        return 30.0; // matching demo
      case SliderM3ESize.large:
        return 45.0;
    }
  }

  double get defaultAnimationSpeed {
    switch (this) {
      case SliderM3ESize.small:
        return 1.4;
      case SliderM3ESize.medium:
        return 1.0;
      case SliderM3ESize.large:
        return 0.8;
    }
  }

  double get defaultThumbWidth {
    switch (this) {
      case SliderM3ESize.small:
        return 3.0;
      case SliderM3ESize.medium:
        return 4.0; // matching demo
      case SliderM3ESize.large:
        return 6.0;
    }
  }

  double get defaultThumbHeight {
    switch (this) {
      case SliderM3ESize.small:
        return 22.0;
      case SliderM3ESize.medium:
        return 30.0; // matching demo
      case SliderM3ESize.large:
        return 40.0;
    }
  }

  double get defaultThumbRadius {
    switch (this) {
      case SliderM3ESize.small:
        return 2.0;
      case SliderM3ESize.medium:
        return 4.0; // matching demo
      case SliderM3ESize.large:
        return 6.0;
    }
  }
}
