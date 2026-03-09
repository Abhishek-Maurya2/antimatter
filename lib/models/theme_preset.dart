import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color seedColor;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.seedColor,
  });

  factory ThemePreset.fromJson(Map<String, dynamic> json) {
    return ThemePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      seedColor: Color(json['seedColor'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'seedColor': seedColor.toARGB32()};
  }
}

// Built-in presets
const List<ThemePreset> builtInPresets = [
  ThemePreset(
    id: 'preset_nordic',
    name: 'Nordic',
    seedColor: Color(0xFF5E81AC),
  ),
  ThemePreset(
    id: 'preset_midnight',
    name: 'Midnight OLED',
    seedColor: Color(0xFF7e57c2),
  ),
  ThemePreset(
    id: 'preset_sakura',
    name: 'Sakura',
    seedColor: Color(0xFFF48FB1),
  ),
  ThemePreset(
    id: 'preset_forest',
    name: 'Forest',
    seedColor: Color(0xFF2E7D32),
  ),
  ThemePreset(id: 'preset_ocean', name: 'Ocean', seedColor: Color(0xFF0277BD)),
  ThemePreset(
    id: 'preset_sunset',
    name: 'Sunset',
    seedColor: Color(0xFFEF6C00),
  ),
];
