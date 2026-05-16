import 'package:latlong2/latlong.dart';
import 'package:practice/features/tour_mode/services/Haversine_formula.dart';

bool isLocationWithinPolylineThreshold(LatLng currentLocation,
    List<LatLng> polylineCoordinates, double threshold) {
  for (var point in polylineCoordinates) {
    double distance = calculateDistance(currentLocation, point);
    if (distance <= threshold) {
      return true;
    }
  }
  return false;
}
