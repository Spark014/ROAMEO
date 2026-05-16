import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';

// Function to read coordinates from a file and create LatLng objects
Future<List<LatLng>> readCoordinatesFromFile(String filePath) async {
  final routePoints = <LatLng>[];

  try {
    // Read the file
    final file = File(filePath);
    final lines = await file.readAsLines();

    // Process each line
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        // Split the line into longitude and latitude
        final parts = line.split(', ');
        if (parts.length == 2) {
          final lng = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);

          // Create a LatLng object and add it to the list
          if (lat != null && lng != null) {
            routePoints.add(LatLng(lat, lng)); // Adjusted to match your request
          }
        }
      }
    }
  } catch (e) {
    print('Error reading file: $e');
  }

  return routePoints;
}