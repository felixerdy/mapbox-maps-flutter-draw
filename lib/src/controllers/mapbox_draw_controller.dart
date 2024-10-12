// lib/src/controllers/mapbox_draw_controller.dart

part of '../mapbox_maps_flutter_draw.dart';

enum EditingMode {
  NONE,
  DRAW_POINT,
  DRAW_LINE,
  DRAW_POLYGON,
  DELETE,
}

class MapboxDrawController with ChangeNotifier {
  // Editing Mode
  EditingMode _editingMode = EditingMode.NONE;
  EditingMode get editingMode => _editingMode;

  // Handlers
  late final PointHandler _pointHandler;
  late final LineHandler _lineHandler;
  late final PolygonHandler _polygonHandler;

  // General State Variables
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MapboxDrawController() {
    _pointHandler = PointHandler(this);
    _lineHandler = LineHandler(this);
    _polygonHandler = PolygonHandler(this);
  }

  /// Initializes the controller with a MapboxMap instance.
  Future<void> initialize(MapboxMap mapController) async {
    _setLoading(true);
    notifyListeners();
    try {
      await _pointHandler.initialize(mapController);
      await _lineHandler.initialize(mapController);
      await _polygonHandler.initialize(mapController);

      mapController.setOnMapTapListener(MapTapHandler().handleMapTap);
    } catch (e) {
      print('Initialization error: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Toggles the editing state and delegates to the appropriate handler.
  Future<void> toggleEditing(EditingMode mode) async {
    _setLoading(true);
    notifyListeners();
    try {
      if (_editingMode == mode) {
        // If already in the desired mode, toggle it off
        _editingMode = EditingMode.NONE;
        // Optionally, finalize the current editing mode
        switch (mode) {
          case EditingMode.DRAW_POINT:
            // No finalization needed for points
            break;
          case EditingMode.DRAW_LINE:
            await _lineHandler.finishDrawing();
            break;
          case EditingMode.DRAW_POLYGON:
            await _polygonHandler.finishDrawing();
            break;
          case EditingMode.DELETE:
            // Handle delete mode exit if necessary
            break;
          default:
            break;
        }
      } else {
        // Switch to the desired mode
        _editingMode = mode;
        // Start the corresponding handler's editing process
        switch (mode) {
          case EditingMode.DRAW_POINT:
            // PointHandler doesn't need to start drawing explicitly
            break;
          case EditingMode.DRAW_LINE:
            await _lineHandler.startDrawing();
            break;
          case EditingMode.DRAW_POLYGON:
            await _polygonHandler.startDrawing();
            break;
          case EditingMode.DELETE:
            // Handle entering delete mode if necessary
            break;
          default:
            break;
        }
      }
    } catch (e) {
      print('Error toggling editing: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Toggles delete mode
  void toggleDeleteMode() {
    toggleEditing(EditingMode.DELETE);
  }

  /// Adds existing points by delegating to PointHandler.
  Future<void> addPoints(List<Point> existingPoints) async {
    await _pointHandler.addPoints(existingPoints);
  }

  /// Retrieves all points by delegating to PointHandler.
  List<Point> getAllPoints() {
    return _pointHandler.getAllPoints();
  }

  Future<void> addLines(List<LineString> lines) async {
    await _lineHandler.addLines(lines);
  }

  List<LineString> getAllLines() {
    return _lineHandler.getAllLines();
  }

  /// Adds existing polygons by delegating to PolygonHandler.
  Future<void> addPolygons(List<Polygon> existingPolygons) async {
    await _polygonHandler.add(existingPolygons);
  }

  /// Retrieves all polygons by delegating to PolygonHandler.
  List<Polygon> getAllPolygons() {
    return _polygonHandler.getAll();
  }

  /// Undo the last action by delegating to the appropriate handler
  Future<void> undoLastAction() async {
    // Depending on the current mode, delegate to the respective handler
    switch (_editingMode) {
      case EditingMode.DRAW_POINT:
        await _pointHandler.undoLastPoint();
        break;
      case EditingMode.DRAW_LINE:
        await _lineHandler.undoLastPoint();
        break;
      case EditingMode.DRAW_POLYGON:
        await _polygonHandler.undoLastPoint();
        break;
      // Handle other modes similarly
      default:
        break;
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
    _pointHandler.dispose();
    _lineHandler.dispose();
    _polygonHandler.dispose();
    // Dispose other handlers:
    super.dispose();
  }
}
