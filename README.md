<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Mapbox Maps Flutter Draw

A Flutter package to draw, edit, and delete points, lines, and polygons on a Mapbox map using the [mapbox_maps_flutter](https://github.com/mapbox/mapbox-maps-flutter) library. This package helps in creating and managing annotations interactively.

## Features

- **Draw Geometries**: Add points, lines, and polygons on the map.
- **Delete Geometries**: Remove existing geometries.
- **Undo Last Edit**: Undo the last edit.
- **Manage Geometries**: Store and retrieve multiple geometries.


<img width="300px" src="./doc/example.png" />

## Getting started

To use this package, add `mapbox_maps_flutter_draw` and its dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  mapbox_maps_flutter: ^<latest_version>
  mapbox_maps_flutter_draw:
  provider:
```

## Usage

Please check out the [example](./example/) project for a full example.

```dart
@override
Widget build(BuildContext context) {
    _mapboxDrawController = Provider.of<MapboxDrawController>(context);

    ...

    // this is the mapbox_maps_flutter (https://github.com/mapbox/mapbox-maps-flutter) map
    MapWidget(
        styleUri: MapboxStyles.STANDARD,
        onMapCreated: (mapInstance) async {
            await _mapboxDrawController.initialize(mapInstance);

            // sample polygons
            final polygonString = [
                '{"type":"Polygon","bbox":null,"coordinates":[[[-18.930236903430682,65.54258945880892],[-41.305603332322534,56.12495372403541],[-23.143507455464942,47.51318115957886],[-13.42744079577011,50.491865810367415]]]}',
                '{"type":"Polygon","bbox":null,"coordinates":[[[19.172957996449043,49.30508658266342],[12.380430916160435,33.47371340190411],[-2.592100951914972,35.36674553163404],[0.04248170102297877,51.60826115068258]]]}'
            ];

            _mapboxDrawController.addPolygons(
                polygonString
                    .map((e) => Polygon.fromJson(jsonDecode(e)))
                    .toList(),
              );
        },
    ),
    IconButton.filled(
        icon: _mapboxDrawController.editingMode == EditingMode.DRAW_POLYGON
            ? const Icon(Icons.done)
            : const Icon(Icons.add),
        onPressed: () =>
            _mapboxDrawController.toggleEditing(),
    ),
    IconButton.filled(
        icon: const Icon(Icons.undo),
        onPressed: (_mapboxDrawController.polygonPoints.isEmpty)
            ? null
            : () => _mapboxDrawController.undoLastPoint(),
    ),
    IconButton.filled(
        icon: const Icon(Icons.delete),
        onPressed: () {
            _mapboxDrawController.toggleDeleteMode();
        },
    )
}
```

## API Overview

### MapboxDrawController
- **`initialize(MapboxMap mapController)`**: Initializes the controller with a Mapbox map instance and sets up the point, line, and polygon handlers.
- **`toggleEditing(EditingMode mode)`**: Toggles the editing state and delegates to the appropriate handler based on the specified editing mode.
- **`toggleDeleteMode()`**: Toggles delete mode, which allows for deletion of points, lines, or polygons.
- **`addPoints(List<Point> existingPoints)`**: Adds existing points to the map by delegating to the `PointHandler`.
- **`getAllPoints()`**: Retrieves all points currently stored by delegating to the `PointHandler`.
- **`addLines(List<LineString> lines)`**: Adds existing lines to the map by delegating to the `LineHandler`.
- **`getAllLines()`**: Retrieves all lines currently stored by delegating to the `LineHandler`.
- **`addPolygons(List<Polygon> existingPolygons)`**: Adds existing polygons to the map by delegating to the `PolygonHandler`.
- **`getAllPolygons()`**: Retrieves all polygons currently stored by delegating to the `PolygonHandler`.
- **`undoLastAction()`**: Undoes the last action performed based on the current editing mode, delegating to the appropriate handler.
- **`dispose()`**: Cleans up the annotation managers for points, lines, and polygons when the controller is no longer needed.


## License
This package is licensed under the [MIT License](./LICENSE).



