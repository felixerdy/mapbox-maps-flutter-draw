// lib/src/controllers/polygon_handler.dart

part of '../mapbox_maps_flutter_draw.dart';

class PolygonHandler extends ChangeNotifier {
  final MapboxDrawController _controller;

  // Private Variables
  final List<Point> _polygonPoints = []; // To store the tapped points
  final List<CircleAnnotation> _circleAnnotations = []; // Circle markers
  PolygonAnnotation? _currentPolygon;
  final List<PolygonAnnotation> polygons = [];

  // Annotation Managers
  CircleAnnotationManager? _circleAnnotationManager;
  PolygonAnnotationManager? _polygonAnnotationManager;

  PolygonHandler(this._controller);

  /// Initializes polygon-related annotation managers.
  Future<void> initialize(MapboxMap mapController) async {
    _circleAnnotationManager = await mapController.annotations
        .createCircleAnnotationManager(id: 'mapbox_draw_polygon_circles');

    _circleAnnotationManager!
      ..setCircleEmissiveStrength(1)
      ..setCirclePitchAlignment(CirclePitchAlignment.MAP)
      ..setCircleColor(Colors.redAccent.value)
      ..setCircleStrokeColor(Colors.white.value)
      ..setCircleStrokeWidth(2)
      ..setCircleRadius(6);

    _polygonAnnotationManager = await mapController.annotations
        .createPolygonAnnotationManager(below: 'mapbox_draw_polygon_circles');

    _polygonAnnotationManager!
      ..setFillEmissiveStrength(1)
      ..setFillColor(Colors.redAccent.value);

    _polygonAnnotationManager!
        .addOnPolygonAnnotationClickListener(_AnnotationClickListener(this));

    // Register PolygonHandler tap listener
    MapTapHandler().addTapListener(_onMapTapListener);
  }

  /// Adds existing polygons to the map.
  Future<void> add(List<Polygon> existingPolygons) async {
    if (_polygonAnnotationManager == null) {
      print('PolygonAnnotationManager is not initialized.');
      return;
    }

    for (final polygon in existingPolygons) {
      try {
        final annotationOption = PolygonAnnotationOptions(
          geometry: polygon,
        );
        final newPolyAnn =
            await _polygonAnnotationManager!.create(annotationOption);
        polygons.add(newPolyAnn);
      } catch (e) {
        print('Error adding polygon: $e');
      }
    }
    _controller.notifyListeners();
  }

  /// Retrieves all polygons from the map.
  List<Polygon> getAll() {
    return polygons.map((e) => e.geometry).toList();
  }

  /// Starts the polygon drawing process.
  Future<void> startDrawing() async {
    // Reset any existing drawing state
    _currentPolygon = null;
    _polygonPoints.clear();
    await _circleAnnotationManager?.deleteAll();
    _circleAnnotations.clear();
    _controller.notifyListeners();
  }

  /// Finishes the polygon drawing process.
  Future<void> finishDrawing() async {
    if (_polygonPoints.length < 3) {
      print('A polygon requires at least 3 points.');
      return;
    }

    try {
      // Create the final polygon
      final newPoly = await _polygonAnnotationManager!.create(
        PolygonAnnotationOptions(
          geometry: Polygon.fromPoints(points: [_polygonPoints.toList()]),
        ),
      );

      polygons.add(newPoly);

      // Clean up
      await _circleAnnotationManager!.deleteAll();
      _circleAnnotations.clear();
      _polygonPoints.clear();
      _currentPolygon = null;

      _controller.notifyListeners();
    } catch (e) {
      print('Error finalizing polygon: $e');
    }
  }

  /// Handles map tap events to add points to the polygon.
  Future<void> _onMapTapListener(MapContentGestureContext context) async {
    print('Polygon points: $_polygonPoints');

    if (_controller.editingMode != EditingMode.DRAW_POLYGON ||
        _controller.isLoading) {
      return; // Only add points when in draw polygon mode and not loading
    }

    print('Adding polygon point: ${context.point}');

    _controller._setLoading(true);
    _polygonPoints.add(context.point);
    _controller.notifyListeners();

    try {
      if (_polygonPoints.length > 2) {
        print('Updating polygon with ${_polygonPoints.length} points');

        // Create polygon if it doesn't exist
        _currentPolygon ??= await _polygonAnnotationManager!.create(
          PolygonAnnotationOptions(
              geometry: Polygon.fromPoints(points: [_polygonPoints.toList()])),
        );

        // Update the polygon with new points
        _currentPolygon?.geometry =
            Polygon.fromPoints(points: [_polygonPoints.toList()]);

        await _polygonAnnotationManager!.update(_currentPolygon!);
      }

      // Create a visual marker (circle) at the tapped point
      final circleAnnotation = await _circleAnnotationManager!.create(
        CircleAnnotationOptions(geometry: context.point),
      );

      // Store the circle annotation for future removal
      _circleAnnotations.add(circleAnnotation);
      _controller.notifyListeners();
    } catch (e) {
      print('Error adding polygon point: $e');
    } finally {
      _controller._setLoading(false);
    }
  }

  /// Deletes a polygon annotation.
  Future<void> deletePolygon(PolygonAnnotation polygon) async {
    try {
      if (_polygonAnnotationManager != null) {
        await _polygonAnnotationManager!.delete(polygon);
        polygons.removeWhere((poly) => poly.id == polygon.id);
        _controller.notifyListeners();
        print('Polygon deleted: $polygon');
      }
    } catch (e) {
      print('Error deleting polygon: $e');
    }
  }

  /// Undoes the last added point and removes the corresponding circle.
  Future<void> undoLastPoint() async {
    if (_polygonPoints.isEmpty || _controller.isLoading) return;

    _controller._setLoading(true);
    _polygonPoints.removeLast();
    _controller.notifyListeners();

    try {
      // Remove the last circle annotation
      if (_circleAnnotations.isNotEmpty) {
        final lastCircle = _circleAnnotations.removeLast();
        await _circleAnnotationManager!.delete(lastCircle);
      }

      if (_polygonPoints.length > 2) {
        // Update the polygon with the remaining points
        _currentPolygon?.geometry =
            Polygon.fromPoints(points: [_polygonPoints.toList()]);

        await _polygonAnnotationManager!.update(_currentPolygon!);
      } else {
        // If less than 3 points, remove the polygon completely
        if (_currentPolygon != null) {
          await _polygonAnnotationManager!.delete(_currentPolygon!);
          _currentPolygon = null;
        }
      }

      _controller.notifyListeners();
    } catch (e) {
      print('Error undoing last polygon point: $e');
    } finally {
      _controller._setLoading(false);
    }
  }

  /// Dispose method to clean up annotation managers.
  @override
  void dispose() {
    super.dispose();
    MapTapHandler().removeTapListener(_onMapTapListener);
    _polygonAnnotationManager?.deleteAll();
    _circleAnnotationManager?.deleteAll();
  }
}

/// Internal class to handle polygon annotation clicks.
class _AnnotationClickListener extends OnPolygonAnnotationClickListener {
  final PolygonHandler _polygonHandler;

  _AnnotationClickListener(this._polygonHandler);

  @override
  void onPolygonAnnotationClick(PolygonAnnotation annotation) {
    if (_polygonHandler._controller.editingMode == EditingMode.DELETE) {
      _polygonHandler.deletePolygon(annotation);
    }
  }
}
