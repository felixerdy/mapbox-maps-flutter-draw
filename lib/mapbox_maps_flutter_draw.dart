library mapbox_maps_flutter_draw;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

enum EditingMode {
  NONE,
  DRAW_POLYGON,
  DELETE,
}

class MapboxDrawController with ChangeNotifier {
  // Private Variables
  final List<Point> _polygonPoints = []; // To store the tapped points
  final List<CircleAnnotation> _circleAnnotations =
      []; // To store circle annotations
  PolygonAnnotation? _currentPolygon;
  bool _isLoading = false; // To track loading state

  CircleAnnotationManager?
      _circleAnnotationManager; // Managing circle annotations
  PolygonAnnotationManager?
      _polygonAnnotationManager; // Managing polygon annotations

  EditingMode _editingMode = EditingMode.NONE;

  // Getters
  EditingMode get editingMode => _editingMode;
  List<Point> get polygonPoints => List.unmodifiable(_polygonPoints);
  PolygonAnnotation? get currentPolygon => _currentPolygon;

  final List<PolygonAnnotation> polygons = [];

  void add(List<Polygon> existingPolygons) async {
    for (final polygon in existingPolygons) {
        final annotationOption = PolygonAnnotationOptions(
          geometry: polygon,
          fillColor: Colors.redAccent.value,
            fillOpacity: 0.5,
        );
        final newPolyAnn = await _polygonAnnotationManager!.create(annotationOption);
        polygons.add(newPolyAnn);
    }
    notifyListeners();
  }

  List<Polygon> getAll() {
    return polygons.map((e) => e.geometry).toList();
  }

  // Call this to toggle delete mode
  void toggleDeleteMode() {
    _editingMode = _editingMode == EditingMode.DELETE
        ? EditingMode.NONE
        : EditingMode.DELETE;

    notifyListeners();
  }

  // Method to delete a polygon
  Future<void> deletePolygon(PolygonAnnotation polygon) async {
    try {
      if (_polygonAnnotationManager != null) {
        await _polygonAnnotationManager!.delete(polygon);
        polygons.removeWhere((poly) => poly.id == polygon.id);
        notifyListeners();
        print('Polygon deleted: $polygon');
      }
    } catch (e) {
      print('Error deleting polygon: $e');
    }
  }

  /// Initializes the controller with a MapboxMap instance.
  Future<void> initialize(MapboxMap mapController) async {
    // Initialize annotation managers
    _circleAnnotationManager = await mapController.annotations
        .createCircleAnnotationManager(id: 'mapbox_draw_circles');

    _circleAnnotationManager!
      ..setCircleEmissiveStrength(1)
      ..setCirclePitchAlignment(CirclePitchAlignment.MAP);

    _polygonAnnotationManager = await mapController.annotations
        .createPolygonAnnotationManager(below: 'mapbox_draw_circles');

    _polygonAnnotationManager!.setFillEmissiveStrength(1);

    _polygonAnnotationManager!
        .addOnPolygonAnnotationClickListener(_AnnotationClickListener(this));

    // Set map tap listener
    mapController.setOnMapTapListener(_onMapTapListener);
  }

  /// Handles map tap events to add points to the polygon.
  Future<void> _onMapTapListener(MapContentGestureContext context) async {
    if (_editingMode != EditingMode.DRAW_POLYGON || _isLoading) {
      return; // Only add points when editing and not loading
    }

    _setLoading(true);
    _polygonPoints.add(context.point);
    notifyListeners();

    try {
      // If there are more than 2 points, update the polygon
      if (_polygonPoints.length > 2) {
        print('Updating polygon with ${_polygonPoints.length} points');

        // Create a polygon if it doesn't exist
        _currentPolygon ??= await _polygonAnnotationManager!.create(
          PolygonAnnotationOptions(
            geometry: Polygon.fromPoints(points: [_polygonPoints.toList()]),
            fillColor: Colors.redAccent.value,
            fillOpacity: 0.5,
          ),
        );

        // Update the polygon with the new points
        _currentPolygon?.geometry =
            Polygon.fromPoints(points: [_polygonPoints.toList()]);

        await _polygonAnnotationManager!.update(_currentPolygon!);
      }

      // Create a visual marker (circle) at the tapped point
      final circleAnnotation = await _circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: context.point,
          circleColor: Colors.redAccent.value,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2,
          circleRadius: 6,
        ),
      );

      // Store the circle annotation for future removal
      _circleAnnotations.add(circleAnnotation);
      notifyListeners();
    } catch (e) {
      print('Error adding point: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggles the editing state and handles related logic.
  Future<void> toggleEditing() async {
    if (_polygonAnnotationManager == null) {
      return;
    }

    _setLoading(true);
    notifyListeners();

    try {
      if (_editingMode == EditingMode.DRAW_POLYGON && _polygonPoints.isEmpty) {
        // If editing and no points, cancel the editing
        _editingMode = EditingMode.NONE;
        notifyListeners();
      } else if (editingMode == EditingMode.DRAW_POLYGON &&
          _polygonPoints.isNotEmpty) {
        // Finalize editing by creating/updating the polygon
        if (_currentPolygon != null) {
          await _polygonAnnotationManager!.delete(_currentPolygon!);
          _currentPolygon = null;
        }

        // Create the final polygon
        final newPoly = await _polygonAnnotationManager!.create(
          PolygonAnnotationOptions(
            geometry: Polygon.fromPoints(points: [_polygonPoints.toList()]),
            fillColor: Colors.redAccent.value,
            fillOpacity: 0.5,
          ),
        );

        polygons.add(newPoly);

        // Remove all circle annotations
        await _circleAnnotationManager!.deleteAll();
        _circleAnnotations.clear();
        _polygonPoints.clear();

        _editingMode = EditingMode.NONE;
        notifyListeners();
      } else {
        // Start editing mode
        _editingMode = EditingMode.DRAW_POLYGON;
        _currentPolygon = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling editing: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Undoes the last added point and removes the corresponding circle.
  Future<void> undoLastPoint() async {
    if (_polygonPoints.isEmpty || _isLoading) return;

    _setLoading(true);
    _polygonPoints.removeLast();
    notifyListeners();

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

      notifyListeners();
    } catch (e) {
      print('Error undoing last point: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the loading state.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Dispose method to clean up annotation managers.
  @override
  void dispose() {
    super.dispose();
  }
}

// Internal class to handle polygon annotation clicks.
class _AnnotationClickListener extends OnPolygonAnnotationClickListener {
  final MapboxDrawController controller; // Add reference to the controller

  _AnnotationClickListener(this.controller);

  @override
  void onPolygonAnnotationClick(PolygonAnnotation annotation) {
    if (controller.editingMode == EditingMode.DELETE) {
      controller.deletePolygon(annotation); // Call delete method
    }
  }
}