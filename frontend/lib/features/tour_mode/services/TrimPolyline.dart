import 'package:latlong2/latlong.dart';
import 'package:practice/features/tour_mode/pages/Ssmplay.dart';
import 'package:practice/features/tour_mode/services/Haversine_formula.dart';

int findClosestPointIndex(LatLng userLocation, List<LatLng> polyline) {

  //get a certain min distance
  double minDistance = double.infinity;

  int closestIndex = 0;
  
  //iterate through every polyline coordinate
  for (int i = 0; i < polyline.length; i++) {

    //calculcate the distance from the user location to the polyline coordinate
    double distance = calculateDistance(userLocation, polyline[i]);
    
    //if the distance is lower than minDistance return the closest polyline index the user is near
    if (distance < minDistance) {
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
  }
  
  return closestIndex;
}
