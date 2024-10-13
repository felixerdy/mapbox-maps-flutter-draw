// lib/src/controllers/line_handler.dart

part of '../mapbox_maps_flutter_draw.dart';

class LineHandler extends GeometryHandler {
  final MapboxDrawController _controller;

  // Private Variables
  final List<Point> _linePoints = []; // To store the tapped points
  final List<CircleAnnotation> _circleAnnotations = []; // Circle markers
  PolylineAnnotation? _currentLine;
  final List<PolylineAnnotation> lines = [];

  // Annotation Managers
  CircleAnnotationManager? _circleAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  Function(GeometryChangeEvent event)? onChange;

  LineHandler(this._controller) : super(_controller);

  /// Initializes line-related annotation managers.
  @override
  Future<void> initialize(MapboxMap mapController,
      {GeometryStyle? style,
      Function(GeometryChangeEvent event)? onChange}) async {
    this.onChange = onChange;

    _circleAnnotationManager = await mapController.annotations
        .createCircleAnnotationManager(id: 'mapbox_draw_line_circles');

    _circleAnnotationManager!
      ..setCircleEmissiveStrength(1)
      ..setCirclePitchAlignment(CirclePitchAlignment.MAP)
      ..setCircleColor(style?.color?.value ?? Colors.green.value)
      ..setCircleStrokeColor(style?.strokeColor?.value ?? Colors.white.value)
      ..setCircleStrokeWidth(style?.strokeWidth ?? 2)
      ..setCircleRadius(style?.width ?? 6);

    _polylineAnnotationManager = await mapController.annotations
        .createPolylineAnnotationManager(below: 'mapbox_draw_line_circles');

    _polylineAnnotationManager!
      ..setLineEmissiveStrength(1)
      ..setLineCap(LineCap.ROUND)
      ..setLineColor(style?.color?.value ?? Colors.green.value)
      ..setLineWidth(style?.width ?? 4)
      ..setLineOpacity(style?.opacity ?? 0.8);

    _polylineAnnotationManager!.addOnPolylineAnnotationClickListener(
        _PolylineAnnotationClickListener(this));

    // Register LineHandler tap listener
    MapTapHandler().addTapListener(_onMapTapListener);
  }

  /// Starts the line drawing process.
  @override
  Future<void> startDrawing() async {
    // Reset any existing drawing state
    _linePoints.clear();
    await _circleAnnotationManager?.deleteAll();
    _circleAnnotations.clear();
    _currentLine = null;
    _controller.notifyListeners();
  }

  /// Finishes the line drawing process.
  @override
  Future<void> finishDrawing() async {
    if (_linePoints.length < 2) {
      print('A line requires at least 2 points.');
      return;
    }

    try {
      // Create the final line
      final newLine = await _polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString.fromPoints(points: _linePoints),
        ),
      );

      lines.add(newLine);

      // Clean up
      await _circleAnnotationManager!.deleteAll();
      _circleAnnotations.clear();
      _linePoints.clear();
      _currentLine = null;

      if (onChange != null) {
        onChange!(GeometryChangeEvent(
            changeType: GeometryChangeType.add,
            geometryType: GeometryType.line));
      }

      _controller.notifyListeners();
    } catch (e) {
      print('Error finalizing line: $e');
    }
  }

  /// Handles map tap events to add points to the line.
  Future<void> _onMapTapListener(MapContentGestureContext context) async {
    if (_controller.editingMode != EditingMode.DRAW_LINE ||
        _controller.isLoading) {
      return; // Only add points when in draw line mode and not loading
    }

    _controller._setLoading(true);
    _linePoints.add(context.point);
    _controller.notifyListeners();

    try {
      // Create a visual marker (circle) at the tapped point
      final circleAnnotation = await _circleAnnotationManager!.create(
        CircleAnnotationOptions(geometry: context.point),
      );

      // Store the circle annotation for future removal
      _circleAnnotations.add(circleAnnotation);

      if (_linePoints.length >= 2) {
        // Create or update the line with new points
        if (_currentLine == null) {
          _currentLine = await _polylineAnnotationManager!.create(
            PolylineAnnotationOptions(
                geometry: LineString.fromPoints(points: _linePoints)),
          );
        } else {
          _currentLine?.geometry = LineString.fromPoints(points: _linePoints);
          await _polylineAnnotationManager!.update(_currentLine!);
        }
      }
      _controller.notifyListeners();
    } catch (e) {
      print('Error adding line point: $e');
    } finally {
      _controller._setLoading(false);
    }
  }

  Future<void> addLines(List<LineString> existingLines) async {
    for (var line in existingLines) {
      try {
        final newLine = await _polylineAnnotationManager!.create(
          PolylineAnnotationOptions(geometry: line),
        );

        lines.add(newLine);
      } catch (e) {
        print('Error adding existing line: $e');
      }
    }
  }

  List<LineString> getAllLines() {
    return lines.map((line) => line.geometry).toList();
  }

  /// Deletes a line annotation.
  Future<void> deleteLine(PolylineAnnotation line) async {
    try {
      if (_polylineAnnotationManager != null) {
        await _polylineAnnotationManager!.delete(line);
        lines.removeWhere((ln) => ln.id == line.id);

        if (onChange != null) {
          onChange!(GeometryChangeEvent(
              changeType: GeometryChangeType.delete,
              geometryType: GeometryType.line));
        }

        _controller.notifyListeners();
      }
    } catch (e) {
      print('Error deleting line: $e');
    }
  }

  /// Undoes the last added point and removes the corresponding circle.
  @override
  Future<void> undoLastAction() async {
    if (_linePoints.isEmpty || _controller.isLoading) return;

    _controller._setLoading(true);
    _linePoints.removeLast();
    _controller.notifyListeners();

    try {
      // Remove the last circle annotation
      if (_circleAnnotations.isNotEmpty) {
        final lastCircle = _circleAnnotations.removeLast();
        await _circleAnnotationManager!.delete(lastCircle);
      }

      if (_linePoints.length >= 2) {
        // Update the line with the remaining points
        _currentLine?.geometry = LineString.fromPoints(points: _linePoints);
        await _polylineAnnotationManager!.update(_currentLine!);
      } else {
        // If less than 2 points, remove the line completely
        if (_currentLine != null) {
          await _polylineAnnotationManager!.delete(_currentLine!);
          _currentLine = null;
        }
      }

      _controller.notifyListeners();
    } catch (e) {
      print('Error undoing last line point: $e');
    } finally {
      _controller._setLoading(false);
    }
  }

  /// Dispose method to clean up annotation managers.
  @override
  void dispose() {
    super.dispose();
    MapTapHandler().removeTapListener(_onMapTapListener);
    _polylineAnnotationManager?.deleteAll();
    _circleAnnotationManager?.deleteAll();
  }
}

/// Internal class to handle line annotation clicks.
class _PolylineAnnotationClickListener
    extends OnPolylineAnnotationClickListener {
  final LineHandler _lineHandler;

  _PolylineAnnotationClickListener(this._lineHandler);

  @override
  void onPolylineAnnotationClick(PolylineAnnotation annotation) {
    if (_lineHandler._controller.editingMode == EditingMode.DELETE) {
      _lineHandler.deleteLine(annotation);
    }
  }
}
