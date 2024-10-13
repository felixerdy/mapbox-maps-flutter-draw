// lib/src/models/geometry_styles.dart

part of '../mapbox_maps_flutter_draw.dart';

class GeometryStyle {
  final Color? color;
  final double? width;
  final Color? strokeColor;
  final double? strokeWidth;
  final double? opacity;

  GeometryStyle({
    this.color,
    this.width,
    this.strokeColor,
    this.strokeWidth,
    this.opacity,
  });
}

class GeometryStyles {
  final GeometryStyle? pointStyle;
  final GeometryStyle? lineStyle;
  final GeometryStyle? polygonStyle;

  GeometryStyles({
    this.pointStyle,
    this.lineStyle,
    this.polygonStyle,
  });

  // Default styles can be defined here
  factory GeometryStyles.defaultStyles() {
    return GeometryStyles(
      pointStyle: GeometryStyle(
          color: Colors.blue,
          width: 6.0,
          strokeColor: Colors.white,
          strokeWidth: 2.0,
          opacity: 0.8),
      lineStyle: GeometryStyle(
          color: Colors.green,
          width: 6.0,
          strokeColor: Colors.white,
          strokeWidth: 2.0,
          opacity: 0.8),
      polygonStyle: GeometryStyle(
          color: Colors.red,
          width: 6.0,
          strokeColor: Colors.white,
          strokeWidth: 2,
          opacity: 0.8),
    );
  }
}
