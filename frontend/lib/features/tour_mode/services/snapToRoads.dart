
// Future<void> snapToRoads(List<LatLng> routePoints) async {
//   // Convert the list of LatLng points to a path string
//   String path = routePoints
//       .map((LatLng point) => '${point.latitude}%2C${point.longitude}')
//       .join('%7C'); // Use '%7C' to separate points and '%2C' to separate lat/lng

//   // Prepare the Google Roads API URL
//   String url =
//       'https://roads.googleapis.com/v1/snapToRoads?'
//       'path=$path&'
//       'interpolate=true&' // Interpolate additional points for smoother results
//       'key=AIzaSyC3G2HDD7YggkkwOPXbp_2sBnUFR3xCBU0'; // Replace with your API key

//   // Make the HTTP request to the Google Roads API
//   var response = await http.get(Uri.parse(url));

//   if (response.statusCode == 200) {
//     var data = json.decode(response.body);

//     // Extract the snapped points from the response
//     List<LatLng> snappedCoordinates = [];
//     for (var snappedPoint in data['snappedPoints']) {
//       double lat = snappedPoint['location']['latitude'];
//       double lng = snappedPoint['location']['longitude'];
//       snappedCoordinates.add(LatLng(lat, lng));
//     }

//     // Update the polyline coordinates with the snapped coordinates
//     setState(() {
//       polylineCoordinates = snappedCoordinates;
//     });

//     print('Snapped to roads successfully!');
//   } else {
//     print('Failed to snap to roads: ${response.statusCode}');
//     print('Response body: ${response.body}');
//   }
// }