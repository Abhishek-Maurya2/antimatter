import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DesktopTitleBar extends StatefulWidget {
  const DesktopTitleBar({super.key});

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void onWindowRestore() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final colorTheme = Theme.of(context).colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(color: colorTheme.surfaceContainer),
      child: Stack(
        children: [
          const DragToMoveArea(child: SizedBox.expand()),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Symbols.blur_on_rounded,
                size: 18,
                color: colorTheme.primary,
                fill: 1,
              ),
              const SizedBox(width: 12),
              Text(
                'AntiMatter',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorTheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              // const SizedBox(width: 12),
              // Icon(
              //   Symbols.keyboard_arrow_down_rounded,
              //   size: 22,
              //   weight: 800,
              //   color: colorTheme.onSurfaceVariant,
              // ),
              const Spacer(),
              _WindowControlButton(
                icon: Symbols.minimize_rounded,
                size: 22,
                onPressed: () => windowManager.minimize(),
              ),
              _WindowControlButton(
                icon: _isMaximized
                    ? Symbols.filter_none_rounded
                    : Symbols.crop_square_rounded,
                size: 16,
                onPressed: () async {
                  if (_isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _WindowControlButton(
                icon: Symbols.close_rounded,
                size: 20,
                isClose: true,
                onPressed: () => windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;
  final double size;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
    this.size = 16,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    Color? hoverColor;
    Color? iconColor = colorTheme.onSurfaceVariant;

    if (widget.isClose) {
      hoverColor = Colors.red.withOpacity(0.8);
      if (_isHovered) {
        iconColor = Colors.white;
      }
    } else {
      hoverColor = colorTheme.onSurfaceVariant.withOpacity(0.1);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: iconColor,
            weight: 1200,
          ),
        ),
      ),
    );
  }
}
