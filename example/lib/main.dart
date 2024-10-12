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
            cameraOptions: CameraOptions(
              center: Point(
                  coordinates: Position(9.738585205431917, 50.54399019335429)),
              zoom: 3.0,
            ),
            onMapCreated: (mapInstance) async {
              await _mapboxDrawController.initialize(mapInstance);

              final pointStrings = [
                '{"type":"Point","bbox":null,"coordinates":[6.570985857967685,55.90719196736157]}',
                '{"type":"Point","bbox":null,"coordinates":[7.092888428831486,54.22721425420093]}',
                '{"type":"Point","bbox":null,"coordinates":[2.706870306689325,55.66167979945064]}'
              ];

              _mapboxDrawController.addPoints(
                pointStrings.map((e) => Point.fromJson(jsonDecode(e))).toList(),
              );

              final lineString = [
                '{"type":"LineString","bbox":null,"coordinates": [[5.064497149207369,54.4540017101983],[3.813159322052627,53.370235277869114],[3.019931253735706,52.046657527032266],[1.8638304795524903,51.04485834976981],[-0.016286782683550882,50.32585635199604],[-2.0376273456993204,49.742916276461386],[-4.908908016624935,49.23640858387719]]}',
              ];

              _mapboxDrawController.addLines(
                lineString
                    .map((e) => LineString.fromJson(jsonDecode(e)))
                    .toList(),
              );

              final polygonString = [
                '{"type":"Polygon","bbox":null,"coordinates":[[[2.4126939197327033,48.854917603709794],[16.345373363928786,48.19160560896381],[13.327841459400304,52.52252131047652],[4.8730709465007465,52.397164989265605],[4.302329069480351,50.799690739582275],[2.4126939197327033,48.854917603709794]]]}',
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

                    // alert
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Saved Features'),
                          content: Column(
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
