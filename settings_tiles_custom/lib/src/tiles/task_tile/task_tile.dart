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
    this.deadline,
    this.subTasks,
    this.backgroundColor,
    this.onPressed,
    this.onLongPress,
    super.key,
    super.visible,
    super.enabled,
    required super.title,
    super.description,
  }) : super(
          icon: IconButton(
            onPressed: enabled ? () => onChanged?.call(!checked) : null,
            icon: Icon(
              checked ? Icons.check : Icons.circle_outlined,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          trailing: null,
        );

  /// Whether the checkbox is checked.
  final bool checked;

  /// Called when the status of the checkbox is changed.
  final void Function(bool? checked)? onChanged;

  /// Optional deadline widget displayed below the description.
  final Widget? deadline;

  /// Optional list of widgets representing sub-tasks.
  final List<SettingTile>? subTasks;

  /// Optional background color for the tile.
  final Color? backgroundColor;

  /// Called when the tile is tapped.
  final VoidCallback? onPressed;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    final mainTile = ListTile(
      tileColor: backgroundColor,
      contentPadding: const EdgeInsets.only(right: 16, left: 16),
      enabled: enabled,
      leading: icon,
      title: title,
      subtitle: (description != null || deadline != null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) description!,
                if (deadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                            child: deadline!,
                          ),
                        ],
                      ),
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
          padding: const EdgeInsets.only(left: 50.0, right: 16, bottom: 12.0),
          styleTile: true,
          tiles: subTasks!,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}
