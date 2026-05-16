import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:practice/features/tour_mode/services/alertDialog.dart';
import 'package:practice/features/tour_mode/services/Haversine_formula.dart';

void checkProximityAndNotify(
  BuildContext context,
  LocationData? currentLocation,
  List<LatLng> waypoints,
  Set<LatLng> reachedNearWaypoints,
  Set<LatLng> reachedWaypoints,
  LatLng? reachedNearDestination,
  LatLng? reachedDestination,
  LatLng? destination,
  Function() getPolyPoints,
  Function(LatLng) updateReachedNearWaypoints,
  Function(LatLng) updateReachedWaypoints,
  Function() updateReachedDestination,
  Function() updateReachedNearDestination,
) {
  if (currentLocation == null) return;

  bool alertShown = false;

  for (LatLng waypoint in waypoints) {
    double distanceToWaypoint = calculateDistance(
      LatLng(currentLocation.latitude!, currentLocation.longitude!),
      waypoint,
    );

    if (distanceToWaypoint <= 200 && !reachedNearWaypoints.contains(waypoint)) {
      showAlertDialog2(context, "You are near a waypoint!");
      updateReachedNearWaypoints(waypoint);
      alertShown = true;
    }

    if (distanceToWaypoint <= 50 && !reachedWaypoints.contains(waypoint)) {
      showAlertDialog2(context, "You have arrived at a waypoint!");
      updateReachedWaypoints(waypoint);
      getPolyPoints();
      alertShown = true;
    }

    if (alertShown) return;
  }

  double distanceToDestination = calculateDistance(
    LatLng(currentLocation.latitude!, currentLocation.longitude!),
    destination!,
  );

  if (distanceToDestination <= 50 &&
      !areLatLngEqual(reachedDestination, destination)) {
    showAlertDialog2(context, "You have arrived at your destination!");
    updateReachedDestination();
  }

  if (distanceToDestination <= 200 &&
      !areLatLngEqual(reachedDestination, destination)) {
    showAlertDialog2(context, "You are near the destination!");
    updateReachedNearDestination();
  }
}

//Lat lang object comparison helper function
bool areLatLngEqual(LatLng? a, LatLng? b) {
  if (a == null || b == null) return false;
  return a.latitude == b.latitude && a.longitude == b.longitude;
}
