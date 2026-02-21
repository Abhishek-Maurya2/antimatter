import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:orches/screens/home_screen.dart';

class SortSplitButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    String sortLabel = 'Newest first';
    if (currentSort == TaskSortOption.oldest) sortLabel = 'Oldest first';
    if (currentSort == TaskSortOption.dueDate) sortLabel = 'Due Date';

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0, top: 4.0, bottom: 8.0),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: colorTheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    // Primary action, could reverse sort or just open menu. Let's make it open menu too for consistency, or do nothing.
                  },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        sortLabel,
                        style: TextStyle(
                          color: colorTheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  height: 40,
                  color: colorTheme.surfaceContainer,
                ),
                InkWell(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  onTapDown: (TapDownDetails details) async {
                    final position = details.globalPosition;
                    final option = await showMenu<TaskSortOption>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        position.dx - 40,
                        position.dy,
                        position.dx + 40,
                        position.dy,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: colorTheme.surfaceContainerHigh,
                      items: [
                        PopupMenuItem(
                          value: TaskSortOption.newest,
                          child: Row(
                            children: [
                              Text(
                                'Newest first',
                                style: TextStyle(color: colorTheme.onSurface),
                              ),
                              if (currentSort == TaskSortOption.newest) ...[
                                Spacer(),
                                Icon(
                                  Symbols.check,
                                  size: 18,
                                  color: colorTheme.primary,
                                ),
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
                                style: TextStyle(color: colorTheme.onSurface),
                              ),
                              if (currentSort == TaskSortOption.oldest) ...[
                                Spacer(),
                                Icon(
                                  Symbols.check,
                                  size: 18,
                                  color: colorTheme.primary,
                                ),
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
                                style: TextStyle(color: colorTheme.onSurface),
                              ),
                              if (currentSort == TaskSortOption.dueDate) ...[
                                Spacer(),
                                Icon(
                                  Symbols.check,
                                  size: 18,
                                  color: colorTheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                    if (option != null) {
                      onSortChanged(option);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Center(
                      child: Icon(
                        Symbols.arrow_drop_down,
                        size: 20,
                        color: colorTheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
