part of '../mapbox_maps_flutter_draw.dart';

class MapTapHandler {
  // List of tap listener callbacks
  final List<Function(MapContentGestureContext)> _tapListeners = [];

  // Singleton pattern (if needed) to ensure only one tap handler
  static final MapTapHandler _instance = MapTapHandler._internal();
  factory MapTapHandler() => _instance;
  MapTapHandler._internal();

  /// Adds a new tap listener to the list
  void addTapListener(Function(MapContentGestureContext) listener) {
    _tapListeners.add(listener);
  }

  /// Removes a tap listener from the list
  void removeTapListener(Function(MapContentGestureContext) listener) {
    _tapListeners.remove(listener);
  }

  /// The centralized onMapTap handler that dispatches the tap event
  void handleMapTap(MapContentGestureContext context) {
    for (var listener in _tapListeners) {
      listener(context); // Dispatch tap event to each listener
    }
  }
}
