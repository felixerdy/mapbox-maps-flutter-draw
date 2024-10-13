part of '../mapbox_maps_flutter_draw.dart';

enum GeometryChangeType { add, delete }

enum GeometryType { point, line, polygon }

class GeometryChangeEvent {
  final GeometryChangeType changeType;
  final GeometryType geometryType;

  GeometryChangeEvent({
    required this.changeType,
    required this.geometryType,
  });

  @override
  String toString() {
    return 'ChangeType: $changeType, GeometryType: $geometryType';
  }
}
