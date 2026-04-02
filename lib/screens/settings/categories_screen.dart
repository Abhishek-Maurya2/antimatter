import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import '../../utils/preferences_helper.dart';
import '../../utils/ui_utils.dart';

class CategoriesScreen extends StatefulWidget {
  final bool isEmbedded;
  const CategoriesScreen({super.key, this.isEmbedded = false});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> _categories = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = PreferencesHelper.getStringList('categories') ?? [];
  }

  void _saveCategories() {
    PreferencesHelper.setStringList('categories', _categories);
  }

  void _addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _categories.contains(trimmed)) return;
    setState(() {
      _categories.add(trimmed);
    });
    _saveCategories();
    _controller.clear();
  }

  void _removeCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
    _saveCategories();
  }

  void _showAddCategorySheet() {
    final colorTheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorTheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorTheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Category',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ClipPath(
                    clipper: PolygonClipper(MaterialShapes.sunny),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorTheme.primaryContainer,
                      ),
                      child: Icon(
                        Symbols.label,
                        fill: 1,
                        color: colorTheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: TextStyle(color: colorTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Category name...',
                        filled: true,
                        fillColor: colorTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                      ),
                      onSubmitted: (val) {
                        _addCategory(val);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ButtonM3E(
                      onPressed: () {
                        _addCategory(_controller.text);
                        Navigator.pop(context);
                      },
                      label: const Text('Save Category'),
                      style: ButtonM3EStyle.filled,
                      size: ButtonM3ESize.lg,
                      shape: ButtonM3EShape.round,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(60, 0, 60, 24),
        child: SafeArea(
          child: ButtonM3E(
            onPressed: _showAddCategorySheet,
            label: const Text('Add Category'),
            icon: const Icon(Symbols.add_circle, size: 28, weight: 700),
            style: ButtonM3EStyle.filled,
            size: ButtonM3ESize.lg,
            shape: ButtonM3EShape.round,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Categories'),
            titleSpacing: widget.isEmbedded ? 16 : 0,
            leadingWidth: widget.isEmbedded ? 0 : 80,
            automaticallyImplyLeading: !widget.isEmbedded,
            leading: widget.isEmbedded
                ? null
                : Center(
                    child: IconButtonM3E(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Symbols.arrow_back_rounded, weight: 700),
                      tooltip: 'Back',
                      variant: IconButtonM3EVariant.tonal,
                      width: IconButtonM3EWidth.wide,
                    ),
                  ),
            backgroundColor: widget.isEmbedded
                ? colorTheme.surfaceContainerLow
                : colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          if (_categories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorTheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: Icon(
                        Symbols.category,
                        size: 48,
                        color: colorTheme.primary.withValues(alpha: 0.3),
                        fill: 1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No categories yet',
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        color: colorTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Add categories to organize your tasks by topic or priority.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorTheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SettingSection(
                tiles: _categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  return SettingActionTile(
                    onTap: () {},
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Symbols.category,
                        fill: 1,
                        color: colorTheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButtonM3E(
                      onPressed: () => _removeCategory(index),
                      icon: const Icon(Symbols.delete),
                      variant: IconButtonM3EVariant.standard,
                      foregroundColor: colorTheme.error,
                      tooltip: 'Delete',
                    ),
                  );
                }).toList(),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
