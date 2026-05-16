import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:practice/features/tour_mode/pages/Ssmplay.dart';
import 'package:practice/features/tour_mode/providers/SightProvider.dart';
import 'package:practice/features/tour_mode/services/alertDialog.dart';
import 'package:provider/provider.dart';

//function to iterate through the sightmode and get the source,waypoints and destination
void assignPoints(
  Map<String, dynamic> sightMode,
  Function(LatLng, LatLng, List<LatLng>, bool) updateStateCallback,
  BuildContext context,
) {
  if (sightMode.isEmpty || !sightMode.containsKey('sights')) {
    showAlertDialog2(context, 'No sights available');
    return;
  }

  List<dynamic> sights = sightMode['sights'];

  if (sights.isEmpty) {
    showAlertDialog2(context, 'No sights available');
    return;
  }

  // Save the sights in the provider
  final sightProvider = Provider.of<SightProvider>(context, listen: false);
  sightProvider.setSights(sights);

  // Get the first sight as source
  var source = sights.first;

  // Get the last sight as destination
  var destin = sights.last;

  // Get the waypoints (exclude the destination)
  var waypointsList = sights.sublist(0, sights.length - 1);

  // Set the state variables
  updateStateCallback(
    LatLng(source['lat'], source['long']),
    LatLng(destin['lat'], destin['long']),
    waypointsList.map((wp) => LatLng(wp['lat'], wp['long'])).toList(),
    true,
  );

  // Log the assigned points
  print(
      'Source: ${source['description']} (${source['lat']}, ${source['long']})');
  print(
      'Destination: ${destin['description']} (${destin['lat']}, ${destin['long']})');
  print('Waypoints: ${waypointsList.length}');
}
