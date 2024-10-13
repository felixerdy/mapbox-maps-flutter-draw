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
      ),
    );
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
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(9.738585205431917, 50.54399019335429),
              ),
              zoom: 3.0,
            ),
            onMapCreated: (mapInstance) async {
              void onChangeHandler(GeometryChangeEvent event) {
                print(event);
              }

              final geometryStyles = GeometryStyles(
                  lineStyle: GeometryStyle(
                color: Colors.red,
                width: 4,
                opacity: 0.8,
              ));

              await _mapboxDrawController.initialize(mapInstance,
                  onChange: onChangeHandler, styles: geometryStyles);

              final pointStrings = [
                '{"type":"Point","coordinates":[6.570985857967685,55.90719196736157]}',
              ];

              _mapboxDrawController.addPoints(
                pointStrings.map((e) => Point.fromJson(jsonDecode(e))).toList(),
              );

              final lineString = [
                '{"type":"LineString","coordinates": [[5.064497149207369,54.4540017101983],[3.813159322052627,53.370235277869114]]}',
              ];

              _mapboxDrawController.addLines(
                lineString
                    .map((e) => LineString.fromJson(jsonDecode(e)))
                    .toList(),
              );

              final polygonString = [
                '{"type":"Polygon","coordinates":[[[2.4126939197327033,48.854917603709794],[16.345373363928786,48.19160560896381],[4.302329069480351,50.799690739582275]]]}',
              ];

              _mapboxDrawController.addPolygons(
                polygonString
                    .map((e) => Polygon.fromJson(jsonDecode(e)))
                    .toList(),
              );
            },
          ),
          // Button for drawing actions
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
                IconButton.filled(
                  icon: const Icon(Icons.radio_button_checked),
                  onPressed: () => _mapboxDrawController
                      .toggleEditing(EditingMode.DRAW_POINT),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.timeline),
                  onPressed: () => _mapboxDrawController
                      .toggleEditing(EditingMode.DRAW_LINE),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.crop_square_outlined),
                  onPressed: () => _mapboxDrawController
                      .toggleEditing(EditingMode.DRAW_POLYGON),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _mapboxDrawController.toggleDeleteMode(),
                ),
              ],
            ),
          ),
          // Save button on the left side
          Positioned(
            left: 8,
            top: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    final points = _mapboxDrawController.getAllPoints();
                    final lines = _mapboxDrawController.getAllLines();
                    final polygons = _mapboxDrawController.getAllPolygons();

                    // Show a dialog with feature counts
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Saved Features'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Points: ${points.length}'),
                              Text('Lines: ${lines.length}'),
                              Text('Polygons: ${polygons.length}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
