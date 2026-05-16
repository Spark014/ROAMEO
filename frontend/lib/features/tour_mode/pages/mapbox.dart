// import 'package:flutter/material.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

// class OfflineMap extends StatefulWidget {
//   @override
//   _OfflineMapState createState() => _OfflineMapState();
// }

// class _OfflineMapState extends State<OfflineMap> {
//   late MapboxMapController mapController;

//   final String accessToken = "pk.eyJ1IjoibWFoaWlyaiIsImEiOiJjbTdqZmF0emkwNjVyMmtzZGx4aDZzdzA1In0.Nv0r2tE031cLt0tI1aBFDQ";
//   final LatLng initialPosition = LatLng(6.9271, 79.8612); // Colombo, Sri Lanka

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Offline Mapbox")),
//       body: MapboxMap(
//         accessToken: accessToken,
//         onMapCreated: _onMapCreated,
//         initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
//         styleString: MapboxStyles.MAPBOX_STREETS, // Can change to offline style
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _downloadOfflineRegion,
//         child: Icon(Icons.download),
//       ),
//     );
//   }

//   void _onMapCreated(MapboxMapController controller) {
//     mapController = controller;
//   }

//   Future<void> _downloadOfflineRegion() async {
//     Directory dir = await getApplicationDocumentsDirectory();
//     String path = "${dir.path}/mapbox_offline";
//     await mapController.downloadOfflineRegion(
//       bounds: LatLngBounds(
//         southwest: LatLng(6.9250, 79.8600),
//         northeast: LatLng(6.9300, 79.8700),
//       ),
//       mapStyleUrl: MapboxStyles.MAPBOX_STREETS,
//       minZoom: 10,
//       maxZoom: 14,
//       regionName: "ColomboOffline",
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Offline map downloaded!")),
//     );
//   }
// }
