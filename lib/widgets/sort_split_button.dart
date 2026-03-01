import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:orches/screens/home_screen.dart';

class SortSplitButton extends StatefulWidget {
  final TaskSortOption currentSort;
  final ValueChanged<TaskSortOption> onSortChanged;
  final ColorScheme colorTheme;

  const SortSplitButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.colorTheme,
  });

  @override
  State<SortSplitButton> createState() => _SortSplitButtonState();
}

class _SortSplitButtonState extends State<SortSplitButton> {
  bool _isLeadingPressed = false;
  bool _isTrailingPressed = false;
  bool _isMenuOpen = false;

  void _showMenu(Offset position) async {
    setState(() {
      _isMenuOpen = true;
    });

    final option = await showMenu<TaskSortOption>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 40,
        position.dy,
        position.dx + 40,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.colorTheme.surfaceContainerHigh,
      items: [
        PopupMenuItem(
          value: TaskSortOption.newest,
          child: Row(
            children: [
              Text(
                'Newest first',
                style: TextStyle(color: widget.colorTheme.onSurface),
              ),
              if (widget.currentSort == TaskSortOption.newest) ...[
                const Spacer(),
                Icon(Symbols.check, size: 18, color: widget.colorTheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: TaskSortOption.oldest,
          child: Row(
            children: [
              Text(
                'Oldest first',
                style: TextStyle(color: widget.colorTheme.onSurface),
              ),
              if (widget.currentSort == TaskSortOption.oldest) ...[
                const Spacer(),
                Icon(Symbols.check, size: 18, color: widget.colorTheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: TaskSortOption.dueDate,
          child: Row(
            children: [
              Text(
                'Due Date',
                style: TextStyle(color: widget.colorTheme.onSurface),
              ),
              if (widget.currentSort == TaskSortOption.dueDate) ...[
                const Spacer(),
                Icon(Symbols.check, size: 18, color: widget.colorTheme.primary),
              ],
            ],
          ),
        ),
      ],
    );

    if (mounted) {
      setState(() {
        _isMenuOpen = false;
      });
      if (option != null) {
        widget.onSortChanged(option);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String sortLabel = 'Newest first';
    if (widget.currentSort == TaskSortOption.oldest) sortLabel = 'Oldest first';
    if (widget.currentSort == TaskSortOption.dueDate) sortLabel = 'Due Date';

    final Color bgColor = widget.colorTheme.primaryContainer;
    final Color fgColor = widget.colorTheme.onSecondaryContainer;

    // Checked color for trailing (since it acts as a toggle while menu is open)
    final Color trailingBgColor = _isMenuOpen
        ? widget.colorTheme.secondaryContainer
        : bgColor;

    // Leading button radii
    final double leadingOuter = _isLeadingPressed ? 8.0 : 20.0;
    final double leadingInner = _isLeadingPressed ? 8.0 : 6.0;

    // Trailing button radii
    final bool trailingActive = _isTrailingPressed || _isMenuOpen;
    final double trailingInner = trailingActive ? 28.0 : 6.0;
    final double trailingOuter = trailingActive ? 28.0 : 20.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0, top: 4.0, bottom: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading Button
            Semantics(
              button: true,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isLeadingPressed = true),
                onTapUp: (_) => setState(() => _isLeadingPressed = false),
                onTapCancel: () => setState(() => _isLeadingPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(leadingOuter),
                      right: Radius.circular(leadingInner),
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(leadingOuter),
                        right: Radius.circular(leadingInner),
                      ),
                      onTap: () {
                        // Match old behavior (does nothing to sort, could show menu)
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                        child: Center(
                          child: Text(
                            sortLabel,
                            style: TextStyle(
                              color: fgColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2.0),
            // Trailing Button
            Semantics(
              button: true,
              checked: _isMenuOpen,
              child: GestureDetector(
                onTapDown: (details) {
                  setState(() => _isTrailingPressed = true);
                  _showMenu(details.globalPosition);
                },
                onTapUp: (_) => setState(() => _isTrailingPressed = false),
                onTapCancel: () => setState(() => _isTrailingPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  height: 40,
                  decoration: BoxDecoration(
                    color: trailingBgColor,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(trailingInner),
                      right: Radius.circular(trailingOuter),
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(trailingInner),
                        right: Radius.circular(trailingOuter),
                      ),
                      onTap: () {
                        // Handled in tapDown to open menu with position
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                        child: Center(
                          child: Icon(
                            Symbols.arrow_drop_down,
                            size: 18,
                            color: fgColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
