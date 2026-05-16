import 'dart:math';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';


//Haversine calcualtion to calculate the distance (for offline purposes)
double calculateDistance(LatLng start, LatLng end) {
  
  const double radius = 6371; 
  double lat1 = start.latitude;
  double lon1 = start.longitude;
  double lat2 = end.latitude;
  double lon2 = end.longitude;

  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return radius * c * 1000; 
}

double _toRadians(double degree) {

  return degree * pi / 180.0;
}
