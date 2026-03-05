import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'motion_physics_engine.dart';

enum SpringButtonVariant { defaultItem, toggle }

enum SpringButtonColorStyle { elevated, filled, tonal, outlined, text }

enum SpringButtonShape { round, square }

enum SpringButtonSize { extraSmall, small, medium, large, extraLarge }

enum SpringIconButtonVariant { defaultItem, toggle }

enum SpringIconButtonColorStyle { filled, tonal, outlined, standard }

enum SpringIconButtonWidth { narrow, defaultWidth, wide }

@Deprecated('Use MotionPhysicsEngine + MaterialMotionPresets instead.')
class MotionSprings {
  static final SpringDescription fastSpatial = MaterialMotionPresets
      .expressive
      .spatialFast
      .toSpringDescription();

  static final SpringDescription fastEffects = MaterialMotionPresets
      .expressive
      .effectsFast
      .toSpringDescription();
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
  final MotionPhysicsEngine? motionEngine;
  final MotionSpeed motionSpeed;
  final double pressedScale;

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
    this.motionEngine,
    this.motionSpeed = MotionSpeed.fast,
    this.pressedScale = 0.95,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with TickerProviderStateMixin {
  late final AnimationController _spatialController;
  late final AnimationController _effectsController;
  late final AnimationController _stateLayerController;

  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;

  MotionPhysicsEngine get _engine =>
      widget.motionEngine ?? context.motionEngine();

  @override
  void initState() {
    super.initState();
    _spatialController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
    _effectsController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
    _stateLayerController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;

    if (widget.variant == SpringButtonVariant.toggle && widget.isSelected) {
      _effectsController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SpringButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant == SpringButtonVariant.toggle &&
        oldWidget.isSelected != widget.isSelected) {
      _animateEffectsTo(widget.isSelected ? 1.0 : 0.0);
    }

    if (oldWidget.motionEngine != widget.motionEngine ||
        oldWidget.motionSpeed != widget.motionSpeed) {
      _refreshStateLayer();
    }
  }

  @override
  void dispose() {
    _spatialController.dispose();
    _effectsController.dispose();
    _stateLayerController.dispose();
    super.dispose();
  }

  void _animateSpatialTo(double target) {
    _engine.animate(
      _spatialController,
      target: target,
      domain: MotionDomain.spatial,
      speed: widget.motionSpeed,
    );
  }

  void _animateEffectsTo(double target) {
    _engine.animate(
      _effectsController,
      target: target,
      domain: MotionDomain.effects,
      speed: MotionSpeed.fast,
    );
  }

  void _animateStateLayerTo(double target) {
    _engine.animate(
      _stateLayerController,
      target: target,
      domain: MotionDomain.effects,
      speed: MotionSpeed.fast,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animateSpatialTo(1.0);
    if (widget.variant == SpringButtonVariant.defaultItem) {
      _animateEffectsTo(1.0);
    }
    _refreshStateLayer();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animateSpatialTo(0.0);
    if (widget.variant == SpringButtonVariant.toggle) {
      final double next = widget.isSelected ? 0.0 : 1.0;
      _animateEffectsTo(next);
    } else {
      _animateEffectsTo(0.0);
    }
    _refreshStateLayer();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animateSpatialTo(0.0);
    _animateEffectsTo(
      widget.variant == SpringButtonVariant.toggle && widget.isSelected
          ? 1.0
          : 0.0,
    );
    _refreshStateLayer();
  }

  void _handleHover(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
    _refreshStateLayer();
  }

  void _handleFocus(bool value) {
    if (_isFocused == value) {
      return;
    }
    setState(() => _isFocused = value);
    _refreshStateLayer();
  }

  void _refreshStateLayer() {
    double target;
    if (_isPressed) {
      target = 0.10;
    } else if (_isFocused) {
      target = 0.10;
    } else if (_isHovered) {
      target = 0.08;
    } else {
      target = 0.0;
    }
    _animateStateLayerTo(target);
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
        return 72.0;
    }
  }

  double _getMinWidth() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 48.0;
      case SpringButtonSize.small:
        return 64.0;
      case SpringButtonSize.medium:
        return 72.0;
      case SpringButtonSize.large:
        return 80.0;
      case SpringButtonSize.extraLarge:
        return 96.0;
    }
  }

  double _getHorizontalPadding() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 8.0;
      case SpringButtonSize.small:
        return 16.0;
      case SpringButtonSize.medium:
        return 24.0;
      case SpringButtonSize.large:
        return 32.0;
      case SpringButtonSize.extraLarge:
        return 40.0;
    }
  }

  double _getVerticalPadding() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 6.0;
      case SpringButtonSize.small:
        return 8.0;
      case SpringButtonSize.medium:
        return 10.0;
      case SpringButtonSize.large:
        return 12.0;
      case SpringButtonSize.extraLarge:
        return 14.0;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 18.0;
      case SpringButtonSize.small:
        return 20.0;
      case SpringButtonSize.medium:
        return 24.0;
      case SpringButtonSize.large:
        return 28.0;
      case SpringButtonSize.extraLarge:
        return 32.0;
    }
  }

  TextStyle? _getTextStyle(ThemeData theme) {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return theme.textTheme.labelSmall;
      case SpringButtonSize.small:
        return theme.textTheme.labelLarge;
      case SpringButtonSize.medium:
        return theme.textTheme.titleSmall;
      case SpringButtonSize.large:
        return theme.textTheme.titleMedium;
      case SpringButtonSize.extraLarge:
        return theme.textTheme.headlineSmall;
    }
  }

  double _getPressedRadius() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
      case SpringButtonSize.small:
        return 8.0;
      case SpringButtonSize.medium:
        return 12.0;
      case SpringButtonSize.large:
      case SpringButtonSize.extraLarge:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseHeight = _getHeight();
    final minWidth = _getMinWidth();
    final px = _getHorizontalPadding();
    final py = _getVerticalPadding();
    final iconSize = _getIconSize();
    final baseTextStyle =
        _getTextStyle(theme)?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      child: FocusableActionDetector(
        onShowFocusHighlight: _handleFocus,
        onShowHoverHighlight: _handleHover,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _spatialController,
              _effectsController,
              _stateLayerController,
            ]),
            builder: (context, child) {
              final spatialVal = _spatialController.value.clamp(0.0, 1.2);
              final effectsVal = _effectsController.value.clamp(0.0, 1.0);
              final stateLayerOpacity = _stateLayerController.value.clamp(
                0.0,
                0.2,
              );

              final scale = (1.0 - ((1.0 - widget.pressedScale) * spatialVal))
                  .clamp(0.88, 1.02);

              final defaultRadius = widget.shape == SpringButtonShape.round
                  ? (baseHeight / 2)
                  : _getPressedRadius();
              final pressedRadius = widget.shape == SpringButtonShape.round
                  ? _getPressedRadius()
                  : (baseHeight / 2);
              final currentRadius =
                  ui.lerpDouble(
                    defaultRadius,
                    pressedRadius,
                    spatialVal.clamp(0.0, 1.0),
                  ) ??
                  defaultRadius;

              // Colors based on style and effectsVal
              Color bgColor;
              Color fgColor;
              Color borderColor = Colors.transparent;
              double elevation = 0.0;

              final bool isActive = widget.variant == SpringButtonVariant.toggle
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
                  elevation = isActive ? 1.0 : 3.0;
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

              final BorderRadius borderRadius = BorderRadius.circular(
                currentRadius,
              );
              final Color stateLayerColor = fgColor.withAlpha(
                (stateLayerOpacity * 255).round().clamp(0, 255),
              );

              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: borderRadius,
                    border: borderColor != Colors.transparent
                        ? Border.all(color: borderColor)
                        : null,
                    boxShadow: elevation > 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(38),
                              blurRadius: elevation * 2,
                              offset: Offset(0, elevation),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: minWidth,
                          minHeight: baseHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: px,
                            vertical: py,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: iconSize,
                                  color: fgColor,
                                ),
                                SizedBox(
                                  width: widget.label.isNotEmpty ? 8.0 : 0.0,
                                ),
                              ],
                              if (widget.label.isNotEmpty)
                                Text(
                                  widget.label,
                                  style: baseTextStyle.copyWith(color: fgColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              color: stateLayerColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
  final MotionPhysicsEngine? motionEngine;
  final MotionSpeed motionSpeed;
  final double pressedScale;

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
    this.motionEngine,
    this.motionSpeed = MotionSpeed.fast,
    this.pressedScale = 0.95,
  });

  @override
  State<SpringIconButton> createState() => _SpringIconButtonState();
}

class _SpringIconButtonState extends State<SpringIconButton>
    with TickerProviderStateMixin {
  late final AnimationController _spatialController;
  late final AnimationController _effectsController;
  late final AnimationController _stateLayerController;

  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;

  MotionPhysicsEngine get _engine =>
      widget.motionEngine ?? context.motionEngine();

  @override
  void initState() {
    super.initState();
    _spatialController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
    _effectsController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;
    _stateLayerController = AnimationController.unbounded(vsync: this)
      ..value = 0.0;

    if (widget.variant == SpringIconButtonVariant.toggle && widget.isSelected) {
      _effectsController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SpringIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant == SpringIconButtonVariant.toggle &&
        oldWidget.isSelected != widget.isSelected) {
      _animateEffectsTo(widget.isSelected ? 1.0 : 0.0);
    }
  }

  @override
  void dispose() {
    _spatialController.dispose();
    _effectsController.dispose();
    _stateLayerController.dispose();
    super.dispose();
  }

  void _animateSpatialTo(double target) {
    _engine.animate(
      _spatialController,
      target: target,
      domain: MotionDomain.spatial,
      speed: widget.motionSpeed,
    );
  }

  void _animateEffectsTo(double target) {
    _engine.animate(
      _effectsController,
      target: target,
      domain: MotionDomain.effects,
      speed: MotionSpeed.fast,
    );
  }

  void _animateStateLayerTo(double target) {
    _engine.animate(
      _stateLayerController,
      target: target,
      domain: MotionDomain.effects,
      speed: MotionSpeed.fast,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animateSpatialTo(1.0);
    if (widget.variant == SpringIconButtonVariant.defaultItem) {
      _animateEffectsTo(1.0);
    }
    _refreshStateLayer();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animateSpatialTo(0.0);
    if (widget.variant == SpringIconButtonVariant.toggle) {
      final double next = widget.isSelected ? 0.0 : 1.0;
      _animateEffectsTo(next);
    } else {
      _animateEffectsTo(0.0);
    }
    _refreshStateLayer();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animateSpatialTo(0.0);
    _animateEffectsTo(
      widget.variant == SpringIconButtonVariant.toggle && widget.isSelected
          ? 1.0
          : 0.0,
    );
    _refreshStateLayer();
  }

  void _handleHover(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
    _refreshStateLayer();
  }

  void _handleFocus(bool value) {
    if (_isFocused == value) {
      return;
    }
    setState(() => _isFocused = value);
    _refreshStateLayer();
  }

  void _refreshStateLayer() {
    double target;
    if (_isPressed) {
      target = 0.10;
    } else if (_isFocused) {
      target = 0.10;
    } else if (_isHovered) {
      target = 0.08;
    } else {
      target = 0.0;
    }
    _animateStateLayerTo(target);
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
        return 72.0;
    }
  }

  double _getWidth() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        switch (widget.width) {
          case SpringIconButtonWidth.narrow:
            return 28.0;
          case SpringIconButtonWidth.defaultWidth:
            return 32.0;
          case SpringIconButtonWidth.wide:
            return 48.0;
        }
      case SpringButtonSize.small:
        switch (widget.width) {
          case SpringIconButtonWidth.narrow:
            return 32.0;
          case SpringIconButtonWidth.defaultWidth:
            return 40.0;
          case SpringIconButtonWidth.wide:
            return 56.0;
        }
      case SpringButtonSize.medium:
        switch (widget.width) {
          case SpringIconButtonWidth.narrow:
            return 40.0;
          case SpringIconButtonWidth.defaultWidth:
            return 48.0;
          case SpringIconButtonWidth.wide:
            return 64.0;
        }
      case SpringButtonSize.large:
        switch (widget.width) {
          case SpringIconButtonWidth.narrow:
            return 48.0;
          case SpringIconButtonWidth.defaultWidth:
            return 56.0;
          case SpringIconButtonWidth.wide:
            return 80.0;
        }
      case SpringButtonSize.extraLarge:
        switch (widget.width) {
          case SpringIconButtonWidth.narrow:
            return 64.0;
          case SpringIconButtonWidth.defaultWidth:
            return 72.0;
          case SpringIconButtonWidth.wide:
            return 96.0;
        }
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
        return 18.0;
      case SpringButtonSize.small:
        return 20.0;
      case SpringButtonSize.medium:
        return 24.0;
      case SpringButtonSize.large:
        return 28.0;
      case SpringButtonSize.extraLarge:
        return 32.0;
    }
  }

  bool _restsAsRound() {
    if (widget.variant != SpringIconButtonVariant.toggle) {
      return widget.shape == SpringButtonShape.round;
    }

    if (widget.shape == SpringButtonShape.round) {
      return !widget.isSelected;
    }

    return widget.isSelected;
  }

  double _getPressedRadius() {
    switch (widget.size) {
      case SpringButtonSize.extraSmall:
      case SpringButtonSize.small:
        return 8.0;
      case SpringButtonSize.medium:
        return 12.0;
      case SpringButtonSize.large:
      case SpringButtonSize.extraLarge:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseHeight = _getHeight();
    final baseWidth = _getWidth();
    final iconSize = _getIconSize();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      child: FocusableActionDetector(
        onShowFocusHighlight: _handleFocus,
        onShowHoverHighlight: _handleHover,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _spatialController,
              _effectsController,
              _stateLayerController,
            ]),
            builder: (context, child) {
              final spatialVal = _spatialController.value.clamp(0.0, 1.2);
              final effectsVal = _effectsController.value.clamp(0.0, 1.0);
              final stateLayerOpacity = _stateLayerController.value.clamp(
                0.0,
                0.2,
              );

              final scale = (1.0 - ((1.0 - widget.pressedScale) * spatialVal))
                  .clamp(0.88, 1.02);

              final bool restsAsRound = _restsAsRound();
              final defaultRadius = restsAsRound
                  ? (baseHeight / 2)
                  : _getPressedRadius();
              final pressedRadius = restsAsRound
                  ? _getPressedRadius()
                  : (baseHeight / 2);
              final currentRadius =
                  ui.lerpDouble(
                    defaultRadius,
                    pressedRadius,
                    spatialVal.clamp(0.0, 1.0),
                  ) ??
                  defaultRadius;

              Color bgColor;
              Color fgColor;
              Color borderColor = Colors.transparent;

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

              final BorderRadius borderRadius = BorderRadius.circular(
                currentRadius,
              );
              final Color stateLayerColor = fgColor.withAlpha(
                (stateLayerOpacity * 255).round().clamp(0, 255),
              );

              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: SizedBox(
                  width: baseWidth,
                  height: baseHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: borderRadius,
                      border: borderColor != Colors.transparent
                          ? Border.all(color: borderColor)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(widget.icon, size: iconSize, color: fgColor),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: borderRadius,
                                color: stateLayerColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
