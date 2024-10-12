import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_maps_flutter_draw/mapbox_maps_flutter_draw.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => MapboxDrawController(),
          ),
        ],
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MapboxDrawController _mapboxDrawController;

  @override
  Widget build(BuildContext context) {
    _mapboxDrawController = Provider.of<MapboxDrawController>(context);

    MapboxOptions.setAccessToken("YOUR_MAPBOX_ACCESS_TOKEN");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Draw'),
      ),
      body: Stack(
        children: [
          MapWidget(
            styleUri: MapboxStyles.STANDARD,
            onMapCreated: (mapInstance) async {
              await _mapboxDrawController.initialize(mapInstance);

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
          Positioned(
            right: 8,
            top: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.undo),
                  onPressed: () => _mapboxDrawController.undoLastAction(),
                ),
                _mapboxDrawController.editingMode == EditingMode.DRAW_POINT
                    ? IconButton.filled(
                        icon: _mapboxDrawController.editingMode ==
                                EditingMode.DRAW_POINT
                            ? const Icon(Icons.done)
                            : const Icon(Icons.radio_button_checked),
                        onPressed: () => _mapboxDrawController
                            .toggleEditing(EditingMode.DRAW_POINT),
                      )
                    : IconButton.outlined(
                        icon: _mapboxDrawController.editingMode ==
                                EditingMode.DRAW_POINT
                            ? const Icon(Icons.done)
                            : const Icon(Icons.radio_button_checked),
                        onPressed: () => _mapboxDrawController
                            .toggleEditing(EditingMode.DRAW_POINT),
                      ),
                _mapboxDrawController.editingMode == EditingMode.DRAW_LINE
                    ? IconButton.filled(
                        icon: _mapboxDrawController.editingMode ==
                                EditingMode.DRAW_LINE
                            ? const Icon(Icons.done)
                            : const Icon(Icons.timeline),
                        onPressed: () => _mapboxDrawController
                            .toggleEditing(EditingMode.DRAW_LINE),
                      )
                    : IconButton.outlined(
                        icon: _mapboxDrawController.editingMode ==
                                EditingMode.DRAW_LINE
                            ? const Icon(Icons.done)
                            : const Icon(Icons.timeline),
                        onPressed: () => _mapboxDrawController
                            .toggleEditing(EditingMode.DRAW_LINE),
                      ),
                _mapboxDrawController.editingMode == EditingMode.DRAW_POLYGON
                    ? IconButton.filled(
                        icon: _mapboxDrawController.editingMode ==
                                EditingMode.DRAW_POLYGON
                            ? const Icon(Icons.done)
                            : const Icon(Icons.crop_square_outlined),
                        onPressed: () => _mapboxDrawController
                            .toggleEditing(EditingMode.DRAW_POLYGON),
                      )
                    : IconButton.outlined(
                        icon: _mapboxDrawController.editingMode ==
                                EditingMode.DRAW_POLYGON
                            ? const Icon(Icons.done)
                            : const Icon(Icons.crop_square_outlined),
                        onPressed: () => _mapboxDrawController
                            .toggleEditing(EditingMode.DRAW_POLYGON),
                      ),
                _mapboxDrawController.editingMode == EditingMode.DELETE
                    ? IconButton.filled(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _mapboxDrawController.toggleDeleteMode();
                        },
                      )
                    : IconButton.outlined(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _mapboxDrawController.toggleDeleteMode();
                        },
                      )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
