// lib/src/controllers/line_handler.dart

part of '../mapbox_maps_flutter_draw.dart';

class LineHandler extends ChangeNotifier {
  final MapboxDrawController _controller;

  // Private Variables
  final List<Point> _linePoints = []; // To store the tapped points
  final List<CircleAnnotation> _circleAnnotations = []; // Circle markers
  PolylineAnnotation? _currentLine;
  final List<PolylineAnnotation> lines = [];

  // Annotation Managers
  CircleAnnotationManager? _circleAnnotationManager;
  PolylineAnnotationManager? _PolylineAnnotationManager;

  LineHandler(this._controller);

  /// Initializes line-related annotation managers.
  Future<void> initialize(MapboxMap mapController) async {
    _circleAnnotationManager = await mapController.annotations
        .createCircleAnnotationManager(id: 'mapbox_draw_line_circles');

    _circleAnnotationManager!
      ..setCircleEmissiveStrength(1)
      ..setCirclePitchAlignment(CirclePitchAlignment.MAP)
      ..setCircleColor(Colors.green.value)
      ..setCircleStrokeColor(Colors.white.value)
      ..setCircleStrokeWidth(2)
      ..setCircleRadius(6);

    _PolylineAnnotationManager = await mapController.annotations
        .createPolylineAnnotationManager(below: 'mapbox_draw_line_circles');

    _PolylineAnnotationManager!
      ..setLineEmissiveStrength(1)
      ..setLineColor(Colors.green.value)
      ..setLineWidth(4);

    _PolylineAnnotationManager!.addOnPolylineAnnotationClickListener(
        _PolylineAnnotationClickListener(this));

    // Register LineHandler tap listener
    MapTapHandler().addTapListener(_onMapTapListener);
  }

  /// Starts the line drawing process.
  Future<void> startDrawing() async {
    // Reset any existing drawing state
    _linePoints.clear();
    await _circleAnnotationManager?.deleteAll();
    _circleAnnotations.clear();
    _currentLine = null;
    _controller.notifyListeners();
  }

  /// Finishes the line drawing process.
  Future<void> finishDrawing() async {
    if (_linePoints.length < 2) {
      print('A line requires at least 2 points.');
      return;
    }

    try {
      // Create the final line
      final newLine = await _PolylineAnnotationManager!.create(
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

      _controller.notifyListeners();
    } catch (e) {
      print('Error finalizing line: $e');
    }
  }

  /// Handles map tap events to add points to the line.
  Future<void> _onMapTapListener(MapContentGestureContext context) async {
    print('Line points: $_linePoints');

    if (_controller.editingMode != EditingMode.DRAW_LINE ||
        _controller.isLoading) {
      return; // Only add points when in draw line mode and not loading
    }

    print('Adding line point: ${context.point}');

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
          _currentLine = await _PolylineAnnotationManager!.create(
            PolylineAnnotationOptions(
                geometry: LineString.fromPoints(points: _linePoints)),
          );
        } else {
          _currentLine?.geometry = LineString.fromPoints(points: _linePoints);
          await _PolylineAnnotationManager!.update(_currentLine!);
        }
      }
      _controller.notifyListeners();
    } catch (e) {
      print('Error adding line point: $e');
    } finally {
      _controller._setLoading(false);
    }
  }

  /// Deletes a line annotation.
  Future<void> deleteLine(PolylineAnnotation line) async {
    try {
      if (_PolylineAnnotationManager != null) {
        await _PolylineAnnotationManager!.delete(line);
        lines.removeWhere((ln) => ln.id == line.id);
        _controller.notifyListeners();
        print('Line deleted: $line');
      }
    } catch (e) {
      print('Error deleting line: $e');
    }
  }

  /// Undoes the last added point and removes the corresponding circle.
  Future<void> undoLastPoint() async {
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
        await _PolylineAnnotationManager!.update(_currentLine!);
      } else {
        // If less than 2 points, remove the line completely
        if (_currentLine != null) {
          await _PolylineAnnotationManager!.delete(_currentLine!);
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
    _PolylineAnnotationManager?.deleteAll();
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
