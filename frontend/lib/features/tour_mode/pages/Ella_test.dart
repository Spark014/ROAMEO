import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:practice/SightSeeingMode/Ella details/Ella_route.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Define the initial camera position
  final CameraPosition _initialCameraPosition = CameraPosition(
    target: EllaroutePoints.first, // Use the first point as the initial target
    zoom: 14,
  );

  // Define the polyline
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    // Initialize the polyline
    _polylines.add(
      Polyline(
        polylineId: PolylineId('route'),
        points: EllaroutePoints,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps with Polyline'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (GoogleMapController controller) {
          setState(() {
            mapController = controller;
          });
        },
        polylines: _polylines, // Add the polyline to the map
      ),
    );
  }
}
