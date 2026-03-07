import 'package:flutter/material.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// A [CustomClipper] that clips its child to the outline of a [RoundedPolygon].
/// The polygon's normalized path (0–1 coordinate space) is scaled to fill [size].
class PolygonClipper extends CustomClipper<Path> {
  final RoundedPolygon polygon;

  const PolygonClipper(this.polygon);

  @override
  Path getClip(Size size) {
    final normalizedPath = polygon.toPath();
    // Use uniform scale to prevent stretching — always 1:1
    final side = size.width < size.height ? size.width : size.height;
    final matrix = Matrix4.diagonal3Values(side, side, 1);
    final scaled = normalizedPath.transform(matrix.storage);
    // Center the scaled path inside the clip bounds
    final bounds = scaled.getBounds();
    final dx = (size.width - bounds.width) / 2 - bounds.left;
    final dy = (size.height - bounds.height) / 2 - bounds.top;
    return scaled.shift(Offset(dx, dy));
  }

  @override
  bool shouldReclip(PolygonClipper oldClipper) => oldClipper.polygon != polygon;
}
