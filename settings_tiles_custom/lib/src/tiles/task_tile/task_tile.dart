import 'package:flutter/material.dart';
import 'package:settings_tiles/src/tiles/setting_tile.dart';
import '../../section/setting_section.dart';

/// Task tile with circular checkbox, title, description, optional deadline, and sub-tasks.
class TaskTile extends SettingTile {
  /// A setting tile designed for tasks, with a leading circular checkbox
  /// and an optional [deadline] widget shown below the description.
  /// Also supports nested [subTasks] displayed below the main content.
  TaskTile({
    required this.checked,
    required this.onChanged,
    required this.titleText,
    this.descriptionText,
    this.labels = const [],
    this.deadlineText,
    this.isDeadlineMissed = false,
    this.subTasks,
    this.backgroundColor,
    this.onPressed,
    this.onLongPress,
    this.trailing,
    super.key,
    super.enabled,
    this.isSelected = false,
  }) : super(
          title: const SizedBox.shrink(), // We'll override the title and subtitle later
          description: null,
          icon: IconButton(
            onPressed: enabled ? () => onChanged?.call(!checked) : null,
            icon: Icon(
              checked ? Icons.check : Icons.circle_outlined,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          trailing: trailing,
        );

  /// Whether the checkbox is checked.
  final bool checked;

  /// Called when the status of the checkbox is changed.
  final void Function(bool? checked)? onChanged;

  /// The text to display for the title
  final String titleText;

  /// Optional text to display for the description
  final String? descriptionText;

  /// Optional sub-labels displayed below the description
  final List<String> labels;

  /// Optional deadline widget displayed below the description.
  final String? deadlineText;

  /// Whether the deadline has been missed.
  final bool isDeadlineMissed;

  /// Optional list of widgets representing sub-tasks.
  final List<SettingTile>? subTasks;

  /// Optional background color for the tile.
  final Color? backgroundColor;

  /// Called when the tile is tapped.
  final VoidCallback? onPressed;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Optional trailing widget shown at the end of the tile.
  final Widget? trailing;

  /// Whether the tile is selected for batch operations.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    final mainTile = ListTile(
      tileColor: isSelected ? colorScheme.tertiaryContainer : backgroundColor,
      shape: isSelected ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(52)) : null,
      selected: isSelected,
      selectedTileColor: colorScheme.tertiaryContainer,
      selectedColor: colorScheme.onTertiaryContainer,
      iconColor: isSelected ? colorScheme.onTertiaryContainer : null,
      textColor: isSelected ? colorScheme.onTertiaryContainer : null,
      contentPadding: const EdgeInsets.only(right: 16, left: 16),
      enabled: enabled,
      leading: icon,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titleText,
              style: TextStyle(
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
              ),
            ),
          ),
          if (deadlineText != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: checked
                      ? Colors.transparent
                      : (isDeadlineMissed ? colorScheme.errorContainer : colorScheme.tertiaryContainer),
                  borderRadius: BorderRadius.circular(20),
                  border: checked ? Border.all(color: colorScheme.outlineVariant) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: checked
                          ? colorScheme.onSurfaceVariant
                          : (isDeadlineMissed ? colorScheme.onErrorContainer : colorScheme.onTertiaryContainer),
                    ),
                    const SizedBox(width: 4),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            decoration: checked ? TextDecoration.lineThrough : null,
                            color: checked
                                ? colorScheme.onSurfaceVariant
                                : (isDeadlineMissed ? colorScheme.onErrorContainer : colorScheme.onTertiaryContainer),
                          ),
                      child: Text(deadlineText!),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      subtitle: (descriptionText != null || labels.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (descriptionText != null)
                  Text(
                    descriptionText!,
                    style: TextStyle(
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (descriptionText == null && labels.isNotEmpty)
                  const SizedBox(
                    height: 4,
                  ),
                if (labels.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: descriptionText != null ? 4.0 : 0),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: labels.map((label) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: checked ? Colors.transparent : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 10, color: colorScheme.onSecondaryContainer),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            )
          : null,
      trailing: trailing,
      onTap: enabled ? (onPressed ?? (onChanged != null ? () => onChanged!(!checked) : null)) : null,
      onLongPress: enabled ? onLongPress : null,
    );

    if (subTasks == null || subTasks!.isEmpty) {
      return mainTile;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mainTile,
        SettingSection(
          padding: const EdgeInsets.only(left: 60.0, right: 10, bottom: 12.0),
          styleTile: true,
          tiles: subTasks!,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}
