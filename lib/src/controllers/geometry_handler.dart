// lib/src/handlers/geometry_handler.dart

part of '../mapbox_maps_flutter_draw.dart';

abstract class GeometryHandler extends ChangeNotifier {
  final MapboxDrawController controller;

  GeometryHandler(this.controller);

  Future<void> initialize(MapboxMap mapController,
      {GeometryStyle? style, Function(GeometryChangeEvent event)? onChange});

  Future<void> startDrawing();

  Future<void> finishDrawing();

  Future<void> undoLastAction();

  @override
  void dispose();
}
