import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

enum SpringButtonVariant { defaultItem, toggle }

enum SpringButtonColorStyle { elevated, filled, tonal, outlined, text }

enum SpringButtonShape { round, square }

enum SpringButtonSize { extraSmall, small, medium, large, extraLarge }

enum SpringIconButtonVariant { defaultItem, toggle }

enum SpringIconButtonColorStyle { filled, tonal, outlined, standard }

enum SpringIconButtonWidth { narrow, defaultWidth, wide }

/// Common spring parameters based on Material 3 Motion Specs
class MotionSprings {
  // Fast Spatial: Damping 0.9, Stiffness 1400 (for size / shape morphs)
  static final fastSpatial = SpringDescription.withDampingRatio(
    ratio: 0.9,
    stiffness: 1400.0,
    mass: 1.0,
  );

  // Fast Effects: Damping 1, Stiffness 3800 (for color / opacity)
  static final fastEffects = SpringDescription.withDampingRatio(
    ratio: 1.0,
    stiffness: 3800.0,
    mass: 1.0,
  );
}

class SpringButton extends StatefulWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;
  final SpringButtonVariant variant;
  final SpringButtonColorStyle colorStyle;
  final SpringButtonShape shape;
  final SpringButtonSize size;
  final bool isSelected; // Used for toggle variant

  const SpringButton({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.variant = SpringButtonVariant.defaultItem,
    this.colorStyle = SpringButtonColorStyle.filled,
    this.shape = SpringButtonShape.round,
    this.size = SpringButtonSize.small,
    this.isSelected = false,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with TickerProviderStateMixin {
  late final AnimationController _spatialController; // For shape & scale
  late final AnimationController _effectsController; // For color/elevation

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _spatialController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
    _effectsController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
  }

  @override
  void didUpdateWidget(SpringButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant == SpringButtonVariant.toggle &&
        oldWidget.isSelected != widget.isSelected) {
      // Animate selection state change
      _animateEffectsTo(widget.isSelected ? 1.0 : 0.0);
      if (!_isPressed) {
        _animateSpatialTo(widget.isSelected ? 1.0 : 0.0);
      }
    }
  }

  @override
  void dispose() {
    _spatialController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  void _animateSpatialTo(double target) {
    _spatialController.animateWith(
      SpringSimulation(
        MotionSprings.fastSpatial,
        _spatialController.value,
        target,
        0.0,
        snapToEnd: true,
      ),
    );
  }

  void _animateEffectsTo(double target) {
    _effectsController.animateWith(
      SpringSimulation(
        MotionSprings.fastEffects,
        _effectsController.value,
        target,
        0.0,
        snapToEnd: true,
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animateSpatialTo(1.0);
    if (widget.variant != SpringButtonVariant.toggle) {
      _animateEffectsTo(1.0);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.variant == SpringButtonVariant.toggle) {
      // Spatial stays morphed if selected, otherwise reverts
      _animateSpatialTo(
        !widget.isSelected ? 1.0 : 0.0,
      ); // Will be updated by state change eventually
    } else {
      _animateSpatialTo(0.0);
      _animateEffectsTo(0.0);
    }
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animateSpatialTo(
      widget.variant == SpringButtonVariant.toggle && widget.isSelected
          ? 1.0
          : 0.0,
    );
    if (widget.variant != SpringButtonVariant.toggle) {
      _animateEffectsTo(0.0);
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 32.0;
      case SpringButtonSize.small:
        return 40.0;
      case SpringButtonSize.medium:
        return 48.0;
      case SpringButtonSize.large:
        return 56.0;
      case SpringButtonSize.extraLarge:
        return 64.0;
    }
  }

  double _getHorizontalPadding() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 12.0;
      case SpringButtonSize.small:
        return 16.0;
      case SpringButtonSize.medium:
        return 20.0;
      case SpringButtonSize.large:
        return 24.0;
      case SpringButtonSize.extraLarge:
        return 28.0;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 18.0;
      case SpringButtonSize.small:
        return 18.0;
      case SpringButtonSize.medium:
        return 24.0;
      case SpringButtonSize.large:
        return 24.0;
      case SpringButtonSize.extraLarge:
        return 28.0;
    }
  }

  TextStyle? _getTextStyle(ThemeData theme) {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return theme.textTheme.labelSmall;
      case SpringButtonSize.small:
        return theme.textTheme.labelLarge;
      case SpringButtonSize.medium:
        return theme.textTheme.bodyLarge;
      case SpringButtonSize.large:
        return theme.textTheme.titleMedium;
      case SpringButtonSize.extraLarge:
        return theme.textTheme.titleLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseHeight = _getHeight();
    final px = _getHorizontalPadding();
    final iconSize = _getIconSize();
    final baseTextStyle =
        _getTextStyle(theme)?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spatialController, _effectsController]),
        builder: (context, child) {
          final spatialVal = _spatialController.value;
          final effectsVal = _effectsController.value;

          // Scale down slightly when pressed/active
          final scale = (1.0 - (0.05 * spatialVal)).clamp(0.9, 1.05);

          // Shape Morphing
          // If Round (default): normal = height/2, pressed/selected = height/4 (square-ish)
          // If Square (default): normal = height/6, pressed/selected = height/2 (round-ish)
          final normalCurve = widget.shape == SpringButtonShape.round
              ? (baseHeight / 2)
              : (baseHeight / 6);
          final morphedCurve = widget.shape == SpringButtonShape.round
              ? (baseHeight / 4)
              : (baseHeight / 2);
          final currentRadius =
              normalCurve + ((morphedCurve - normalCurve) * spatialVal);

          // Colors based on style and effectsVal
          Color bgColor;
          Color fgColor;
          Color borderColor = Colors.transparent;
          double elevation = 0.0;

          bool isActive = widget.variant == SpringButtonVariant.toggle
              ? widget.isSelected
              : _isPressed;

          switch (widget.colorStyle) {
            case SpringButtonColorStyle.elevated:
              bgColor =
                  Color.lerp(
                    colorScheme.surfaceContainerLow,
                    colorScheme.primaryContainer,
                    effectsVal,
                  ) ??
                  colorScheme.surfaceContainerLow;
              fgColor = colorScheme.primary;
              elevation = isActive ? 1.0 : 3.0; // lowers when pressed
              break;
            case SpringButtonColorStyle.filled:
              bgColor =
                  Color.lerp(
                    colorScheme.primary,
                    colorScheme.inversePrimary,
                    effectsVal,
                  ) ??
                  colorScheme.primary;
              fgColor =
                  Color.lerp(
                    colorScheme.onPrimary,
                    colorScheme.primary,
                    effectsVal,
                  ) ??
                  colorScheme.onPrimary;
              if (widget.variant == SpringButtonVariant.toggle &&
                  widget.isSelected) {
                bgColor = colorScheme.primary;
                fgColor = colorScheme.onPrimary;
              } else if (widget.variant == SpringButtonVariant.toggle &&
                  !widget.isSelected) {
                bgColor = colorScheme.surfaceContainerHighest;
                fgColor = colorScheme.onSurfaceVariant;
              }
              break;
            case SpringButtonColorStyle.tonal:
              bgColor =
                  Color.lerp(
                    colorScheme.secondaryContainer,
                    colorScheme.primaryContainer,
                    effectsVal,
                  ) ??
                  colorScheme.secondaryContainer;
              fgColor =
                  Color.lerp(
                    colorScheme.onSecondaryContainer,
                    colorScheme.onPrimaryContainer,
                    effectsVal,
                  ) ??
                  colorScheme.onSecondaryContainer;
              break;
            case SpringButtonColorStyle.outlined:
              bgColor =
                  Color.lerp(
                    Colors.transparent,
                    colorScheme.primary.withAlpha(20),
                    effectsVal,
                  ) ??
                  Colors.transparent;
              fgColor = colorScheme.primary;
              borderColor = colorScheme.outline;
              if (widget.variant == SpringButtonVariant.toggle &&
                  widget.isSelected) {
                bgColor = colorScheme.inverseSurface;
                fgColor = colorScheme.onInverseSurface;
                borderColor = Colors.transparent;
              }
              break;
            case SpringButtonColorStyle.text:
              bgColor =
                  Color.lerp(
                    Colors.transparent,
                    colorScheme.primary.withAlpha(20),
                    effectsVal,
                  ) ??
                  Colors.transparent;
              fgColor = colorScheme.primary;
              if (widget.variant == SpringButtonVariant.toggle &&
                  widget.isSelected) {
                bgColor = colorScheme.primaryContainer;
                fgColor = colorScheme.onPrimaryContainer;
              } else if (widget.variant == SpringButtonVariant.toggle &&
                  !widget.isSelected) {
                fgColor = colorScheme.onSurfaceVariant;
              }
              break;
          }

          Widget buttonContent = Container(
            height: baseHeight,
            padding: EdgeInsets.symmetric(horizontal: px),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(currentRadius),
              border: borderColor != Colors.transparent
                  ? Border.all(color: borderColor)
                  : null,
              boxShadow: elevation > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: elevation * 2,
                        offset: Offset(0, elevation),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: iconSize, color: fgColor),
                  SizedBox(width: (widget.label.isNotEmpty) ? 8 : 0),
                ],
                if (widget.label.isNotEmpty)
                  Text(
                    widget.label,
                    style: baseTextStyle.copyWith(color: fgColor),
                  ),
              ],
            ),
          );

          return Transform.scale(scale: scale, child: buttonContent);
        },
      ),
    );
  }
}

class SpringIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final SpringIconButtonVariant variant;
  final SpringIconButtonColorStyle colorStyle;
  final SpringButtonShape shape;
  final SpringButtonSize size;
  final SpringIconButtonWidth width;
  final bool isSelected; // Used for toggle variant

  const SpringIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = SpringIconButtonVariant.defaultItem,
    this.colorStyle = SpringIconButtonColorStyle.standard,
    this.shape = SpringButtonShape.round,
    this.size = SpringButtonSize.small,
    this.width = SpringIconButtonWidth.defaultWidth,
    this.isSelected = false,
  });

  @override
  State<SpringIconButton> createState() => _SpringIconButtonState();
}

class _SpringIconButtonState extends State<SpringIconButton>
    with TickerProviderStateMixin {
  late final AnimationController _spatialController;
  late final AnimationController _effectsController;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _spatialController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
    _effectsController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
  }

  @override
  void didUpdateWidget(SpringIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant == SpringIconButtonVariant.toggle &&
        oldWidget.isSelected != widget.isSelected) {
      _animateEffectsTo(widget.isSelected ? 1.0 : 0.0);
      if (!_isPressed) {
        _animateSpatialTo(widget.isSelected ? 1.0 : 0.0);
      }
    }
  }

  @override
  void dispose() {
    _spatialController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  void _animateSpatialTo(double target) {
    _spatialController.animateWith(
      SpringSimulation(
        MotionSprings.fastSpatial,
        _spatialController.value,
        target,
        0.0,
        snapToEnd: true,
      ),
    );
  }

  void _animateEffectsTo(double target) {
    _effectsController.animateWith(
      SpringSimulation(
        MotionSprings.fastEffects,
        _effectsController.value,
        target,
        0.0,
        snapToEnd: true,
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animateSpatialTo(1.0);
    if (widget.variant != SpringIconButtonVariant.toggle) {
      _animateEffectsTo(1.0);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.variant == SpringIconButtonVariant.toggle) {
      _animateSpatialTo(!widget.isSelected ? 1.0 : 0.0);
    } else {
      _animateSpatialTo(0.0);
      _animateEffectsTo(0.0);
    }
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animateSpatialTo(
      widget.variant == SpringIconButtonVariant.toggle && widget.isSelected
          ? 1.0
          : 0.0,
    );
    if (widget.variant != SpringIconButtonVariant.toggle) {
      _animateEffectsTo(0.0);
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 32.0;
      case SpringButtonSize.small:
        return 40.0;
      case SpringButtonSize.medium:
        return 48.0;
      case SpringButtonSize.large:
        return 56.0;
      case SpringButtonSize.extraLarge:
        return 64.0;
    }
  }

  double _getWidth(double baseHeight) {
    switch (widget.width) {
      case SpringIconButtonWidth.narrow:
        return baseHeight * 0.8;
      case SpringIconButtonWidth.defaultWidth:
        return baseHeight;
      case SpringIconButtonWidth.wide:
        return baseHeight * 1.5;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 18.0;
      case SpringButtonSize.small:
        return 24.0;
      case SpringButtonSize.medium:
        return 28.0;
      case SpringButtonSize.large:
        return 32.0;
      case SpringButtonSize.extraLarge:
        return 36.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseHeight = _getHeight();
    final baseWidth = _getWidth(baseHeight);
    final iconSize = _getIconSize();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spatialController, _effectsController]),
        builder: (context, child) {
          final spatialVal = _spatialController.value;
          final effectsVal = _effectsController.value;

          final scale = (1.0 - (0.05 * spatialVal)).clamp(0.9, 1.05);

          // Morph shape logic similar to SpringButton
          final normalCurve = widget.shape == SpringButtonShape.round
              ? (baseHeight / 2)
              : (baseHeight / 6);
          final morphedCurve = widget.shape == SpringButtonShape.round
              ? (baseHeight / 4)
              : (baseHeight / 2);
          final currentRadius =
              normalCurve + ((morphedCurve - normalCurve) * spatialVal);

          Color bgColor;
          Color fgColor;
          Color borderColor = Colors.transparent;

          // ignore: unused_local_variable
          bool isActive = widget.variant == SpringIconButtonVariant.toggle
              ? widget.isSelected
              : _isPressed;

          switch (widget.colorStyle) {
            case SpringIconButtonColorStyle.filled:
              bgColor =
                  Color.lerp(
                    colorScheme.primary,
                    colorScheme.inversePrimary,
                    effectsVal,
                  ) ??
                  colorScheme.primary;
              fgColor = colorScheme.onPrimary;
              if (widget.variant == SpringIconButtonVariant.toggle) {
                bgColor = widget.isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest;
                fgColor = widget.isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant;
              }
              break;
            case SpringIconButtonColorStyle.tonal:
              bgColor =
                  Color.lerp(
                    colorScheme.secondaryContainer,
                    colorScheme.primaryContainer,
                    effectsVal,
                  ) ??
                  colorScheme.secondaryContainer;
              fgColor = colorScheme.onSecondaryContainer;
              if (widget.variant == SpringIconButtonVariant.toggle) {
                bgColor = widget.isSelected
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest;
                fgColor = widget.isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant;
              }
              break;
            case SpringIconButtonColorStyle.outlined:
              bgColor =
                  Color.lerp(
                    Colors.transparent,
                    colorScheme.primary.withAlpha(20),
                    effectsVal,
                  ) ??
                  Colors.transparent;
              fgColor = colorScheme.onSurfaceVariant;
              borderColor = colorScheme.outline;
              if (widget.variant == SpringIconButtonVariant.toggle &&
                  widget.isSelected) {
                bgColor = colorScheme.inverseSurface;
                fgColor = colorScheme.onInverseSurface;
                borderColor = Colors.transparent;
              }
              break;
            case SpringIconButtonColorStyle.standard:
              bgColor =
                  Color.lerp(
                    Colors.transparent,
                    colorScheme.onSurface.withAlpha(20),
                    effectsVal,
                  ) ??
                  Colors.transparent;
              fgColor = colorScheme.onSurfaceVariant;
              if (widget.variant == SpringIconButtonVariant.toggle &&
                  widget.isSelected) {
                fgColor = colorScheme.primary;
              }
              break;
          }

          return Transform.scale(
            scale: scale,
            child: Container(
              width: baseWidth,
              height: baseHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(currentRadius),
                border: borderColor != Colors.transparent
                    ? Border.all(color: borderColor)
                    : null,
              ),
              child: Icon(widget.icon, size: iconSize, color: fgColor),
            ),
          );
        },
      ),
    );
  }
}
