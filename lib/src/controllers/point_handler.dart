// lib/src/controllers/point_handler.dart

part of '../mapbox_maps_flutter_draw.dart';

class PointHandler extends GeometryHandler {
  final MapboxDrawController _controller;

  // Private Variables
  final List<CircleAnnotation> _points = []; // To store circle annotations

  // Annotation Manager
  CircleAnnotationManager? _circleAnnotationManager;

  PointHandler(this._controller) : super(_controller);

  /// Initializes point-related annotation managers.
  @override
  Future<void> initialize(MapboxMap mapController,
      {GeometryStyle? style}) async {
    _circleAnnotationManager = await mapController.annotations
        .createCircleAnnotationManager(id: 'mapbox_draw_circles');

    // Optionally, set default properties for circle annotations
    _circleAnnotationManager!
      ..setCirclePitchAlignment(CirclePitchAlignment.MAP)
      ..setCircleRadius(style?.width ?? 6)
      ..setCircleColor(style?.color?.value ?? Colors.blue.value)
      ..setCircleStrokeColor(style?.strokeColor?.value ?? Colors.white.value)
      ..setCircleStrokeWidth(style?.strokeWidth ?? 2)
      ..setCircleOpacity(style?.opacity ?? 0.8)
      ..setCircleStrokeOpacity(style?.opacity ?? 0.8);

    _circleAnnotationManager!.addOnCircleAnnotationClickListener(
        _PointAnnotationClickListener(this));

    // Register the PointHandler tap listener with the central MapTapHandler
    MapTapHandler().addTapListener(_onMapTapListener);
  }

  /// Adds a single circle to the map.
  Future<void> addPoint(Point point) async {
    if (_circleAnnotationManager == null) {
      print('CircleAnnotationManager is not initialized.');
      return;
    }

    try {
      final annotationOption = CircleAnnotationOptions(geometry: point);
      final newCircleAnn =
          await _circleAnnotationManager!.create(annotationOption);
      _points.add(newCircleAnn);
      notifyListeners();
    } catch (e) {
      print('Error adding circle: $e');
    }
  }

  /// Adds multiple existing circles to the map.
  Future<void> addPoints(List<Point> existingPoints) async {
    if (_circleAnnotationManager == null) {
      print('CircleAnnotationManager is not initialized.');
      return;
    }

    try {
      for (final point in existingPoints) {
        final annotationOption = CircleAnnotationOptions(geometry: point);
        final newCircleAnn =
            await _circleAnnotationManager!.create(annotationOption);
        _points.add(newCircleAnn);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding circles: $e');
    }
  }

  /// Retrieves all points (as geometries) from the map.
  List<Point> getAllPoints() {
    return _points.map((e) => e.geometry).toList();
  }

  /// Deletes a circle annotation.
  Future<void> deletePoint(CircleAnnotation circle) async {
    try {
      if (_circleAnnotationManager != null) {
        await _circleAnnotationManager!.delete(circle);
        _points.removeWhere((p) => p.id == circle.id);
        notifyListeners();
        print('Circle deleted: $circle');
      }
    } catch (e) {
      print('Error deleting circle: $e');
    }
  }

  /// Undoes the last added circle.
  @override
  Future<void> undoLastAction() async {
    if (_points.isEmpty) return;

    try {
      final lastCircle = _points.removeLast();
      await _circleAnnotationManager!.delete(lastCircle);
      notifyListeners();
    } catch (e) {
      print('Error undoing last circle: $e');
    }
  }

  /// Handles map tap events to add circles to the map.
  Future<void> _onMapTapListener(MapContentGestureContext context) async {
    if (_controller.editingMode != EditingMode.DRAW_POINT ||
        _controller.isLoading) {
      return; // Only add circles when in draw point mode and not loading
    }

    _controller._setLoading(true);

    try {
      await addPoint(context.point);
    } finally {
      _controller._setLoading(false);
    }
  }

  /// Dispose method to clean up annotation managers.
  @override
  void dispose() {
    MapTapHandler().removeTapListener(_onMapTapListener); // Remove listener
    _circleAnnotationManager?.deleteAll();
    super.dispose();
  }

  @override
  Future<void> finishDrawing() {
    return Future.value();
  }

  @override
  Future<void> startDrawing() {
    return Future.value();
  }
}

/// Internal class to handle point annotation clicks.
class _PointAnnotationClickListener extends OnCircleAnnotationClickListener {
  final PointHandler _pointHandler;

  _PointAnnotationClickListener(this._pointHandler);

  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    if (_pointHandler._controller.editingMode == EditingMode.DELETE) {
      _pointHandler.deletePoint(annotation);
    }
  }
}
