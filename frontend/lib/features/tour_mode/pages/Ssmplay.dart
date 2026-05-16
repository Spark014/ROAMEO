import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:practice/SightSeeingMode/Services/SightGet.dart';
import 'package:practice/features/tour_mode/models/DetailWidget.dart';
import 'package:practice/features/tour_mode/services/Haversine_formula.dart';
import 'package:practice/features/tour_mode/services/TrimPolyline.dart';
import 'package:practice/features/tour_mode/services/assignPoints.dart';
import 'package:practice/features/tour_mode/services/alertDialog.dart';
import 'package:practice/features/tour_mode/services/checkProximity.dart';
import 'package:practice/features/tour_mode/services/PolylineThresholdCheck.dart';

class SsmPlay extends StatefulWidget {
  final int index;
  final String docId;

  const SsmPlay({super.key, required this.index, required this.docId});

  @override
  State<SsmPlay> createState() => SsmPlayState();
}

class SsmPlayState extends State<SsmPlay> {
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  bool isLoading = true;
  static bool isDataLoaded = true;
  Map<String, dynamic>? sightMode;
  Set<LatLng> reachedNearWaypoints = {};
  Set<LatLng> reachedWaypoints = {};
  LatLng? reachedDestination;
  LatLng? reachedNearDestination;
  final MapController _mapController = MapController();
  static LatLng? sourceLocation;
  static LatLng? destination;
  static List<LatLng> waypoints = [];
  List<Map<String, dynamic>> navigationSteps = [];
  int currentStepIndex = 0;
  static List<LatLng> polylineCoordinates = [];
  List<PolylineWayPoint> activeWaypoints = [];
  LocationData? currentLocation;
  String distance = '';
  String duration = '';
  String waypointDistance = "";
  String waypointDuration = "";
  List<Marker> markers = [];
  Map<String, dynamic>? currentpointDetails;
  bool showDestinationInfo = false;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  bool get _hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  void resetStaticVariables() {
    isDataLoaded = true;
    sourceLocation = null;
    destination = null;
    waypoints.clear();
    polylineCoordinates.clear();
  }

  void updateAssignPointsState(
      LatLng source, LatLng dest, List<LatLng> wps, bool loaded) {
    setState(() {
      sourceLocation = source;
      destination = dest;
      waypoints = wps;
      isDataLoaded = loaded;
    });
  }

  @override
  void dispose() {
    resetStaticVariables();
    super.dispose();
  }

  void updateReachedNearWaypoints(LatLng waypoint) {
    setState(() => reachedNearWaypoints.add(waypoint));
  }

  void updateReachedWaypoints(LatLng waypoint) {
    setState(() => reachedWaypoints.add(waypoint));
  }

  void updateReachedDestination() {
    setState(() => reachedDestination = destination);
  }

  void updateReachedNearDestination() {
    setState(() => reachedNearDestination = destination);
  }

  void getCurrentLocation() async {
    Location location = Location();
    location.getLocation().then((loc) {
      setState(() => currentLocation = loc);
      getPolyPoints();
    });

    location.onLocationChanged.listen((newLoc) {
      setState(() => currentLocation = newLoc);

      addMarkers();
      trimPolyline(LatLng(newLoc.latitude!, newLoc.longitude!));

      checkProximityAndNotify(
        context,
        currentLocation,
        waypoints,
        reachedNearWaypoints,
        reachedWaypoints,
        reachedNearDestination,
        reachedDestination,
        destination,
        getPolyPoints,
        updateReachedNearWaypoints,
        updateReachedWaypoints,
        updateReachedDestination,
        updateReachedNearDestination,
      );

      LatLng currentLatLng = LatLng(newLoc.latitude!, newLoc.longitude!);
      if (!isLocationWithinPolylineThreshold(
          currentLatLng, polylineCoordinates, 50.0)) {
        getPolyPoints();
      }

      if (activeWaypoints.isNotEmpty) {
        getWaypointDistanceandDuration(currentLocation, activeWaypoints[0]);
      }
      getDistanceAndDuration();

      if (navigationSteps.isEmpty ||
          currentStepIndex >= navigationSteps.length) {
        return;
      }

      LatLng userLatLng = LatLng(newLoc.latitude!, newLoc.longitude!);
      double distanceToStep = calculateDistance(
          userLatLng, navigationSteps[currentStepIndex]['distance']);

      setState(() {
        navigationSteps[currentStepIndex]['distance'] = distanceToStep;
      });

      if (distanceToStep < 10) {
        setState(() => currentStepIndex++);
      }

      _mapController.move(
          LatLng(newLoc.latitude!, newLoc.longitude!), 15.5);
    });
  }

  void getPolyPoints() async {
    if (!_hasApiKey || currentLocation == null || destination == null) return;

    PolylinePoints polylinePoints = PolylinePoints();
    polylineCoordinates.clear();

    activeWaypoints = waypoints
        .where((wp) => !reachedWaypoints.contains(wp))
        .map((wp) =>
            PolylineWayPoint(location: "${wp.latitude},${wp.longitude}"))
        .toList();

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiKey!,
        request: PolylineRequest(
          origin: PointLatLng(
              currentLocation!.latitude!, currentLocation!.longitude!),
          destination:
              PointLatLng(destination!.latitude, destination!.longitude),
          mode: TravelMode.driving,
          wayPoints: activeWaypoints,
          optimizeWaypoints: true,
        ),
      );

      if (result.points.isNotEmpty) {
        final routePoints = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        setState(() => polylineCoordinates = routePoints);
      }
    } catch (e) {
      debugPrint('Polyline fetch failed: $e');
    }
  }

  Future<void> getDistanceAndDuration() async {
    if (!_hasApiKey || currentLocation == null || destination == null) return;
    LatLng currentLatLng =
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
    String waypointsString =
        activeWaypoints.map((wp) => wp.location).join('|');

    String url = waypointsString.isNotEmpty
        ? 'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${destination!.latitude},${destination!.longitude}&waypoints=optimize:true|$waypointsString&key=$apiKey'
        : 'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${destination!.latitude},${destination!.longitude}&key=$apiKey';

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      var data = json.decode(response.body);
      if (data['routes'].isEmpty) return;

      var legs = data['routes'][0]['legs'];
      double totalDistance = 0;
      double totalDuration = 0;
      for (var leg in legs) {
        totalDistance += leg['distance']['value'];
        totalDuration += leg['duration']['value'];
      }

      setState(() {
        distance = '${(totalDistance / 1000).toStringAsFixed(1)} km';
        duration = '${(totalDuration / 60).toStringAsFixed(0)} mins';
      });
    } catch (e) {
      debugPrint('Directions fetch failed: $e');
    }
  }

  Future<void> getWaypointDistanceandDuration(
      LocationData? currentLocation, PolylineWayPoint waypoint) async {
    if (!_hasApiKey || currentLocation == null) return;
    LatLng currentLatLng =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);
    LatLng waypointLatLng = LatLng(
      double.parse(waypoint.location.split(',')[0]),
      double.parse(waypoint.location.split(',')[1]),
    );

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${waypointLatLng.latitude},${waypointLatLng.longitude}&mode=driving&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (data['routes'].isEmpty) return;

      final legs = data['routes'][0]['legs'][0];
      setState(() {
        waypointDistance = legs['distance']['text'];
        waypointDuration = legs['duration']['text'];
      });

      final stepsList = <Map<String, dynamic>>[];
      for (var step in legs['steps']) {
        String instruction =
            step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
        double distance = step['distance']['value'].toDouble();
        stepsList.add({'instruction': instruction, 'distance': distance});
      }

      setState(() {
        navigationSteps = stepsList;
        currentStepIndex = 0;
      });
    } catch (e) {
      debugPrint('Waypoint directions failed: $e');
    }
  }

  void trimPolyline(LatLng userLocation) {
    if (polylineCoordinates.isEmpty) return;
    int closestIndex = findClosestPointIndex(userLocation, polylineCoordinates);
    setState(() {
      polylineCoordinates = polylineCoordinates.sublist(closestIndex);
    });
  }

  void addMarkers() {
    markers.clear();

    if (sightMode == null ||
        sightMode!['sights'] == null ||
        sightMode!['sights'].isEmpty) {
      return;
    }

    List<dynamic> sights = sightMode!['sights'];
    if (waypoints.isEmpty) return;

    for (int i = 0; i < waypoints.length; i++) {
      if (i >= sights.length) continue;
      final waypointDetails = sights[i];
      final point = waypoints[i];

      markers.add(
        Marker(
          point: point,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              _mapController.move(point, 18);
              setState(() {
                showDestinationInfo = true;
                currentpointDetails = waypointDetails;
              });
            },
            child: const Icon(Icons.location_on,
                color: Colors.lightBlueAccent, size: 44),
          ),
        ),
      );
    }

    if (destination != null && sights.isNotEmpty) {
      final destinationDetails = sights.last;
      markers.add(
        Marker(
          point: destination!,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              _mapController.move(destination!, 18);
              setState(() {
                showDestinationInfo = true;
                currentpointDetails = destinationDetails;
              });
            },
            child: const Icon(Icons.flag, color: Colors.redAccent, size: 44),
          ),
        ),
      );
    }

    if (currentLocation != null) {
      markers.add(
        Marker(
          point:
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          width: 32,
          height: 32,
          child: const Icon(Icons.my_location,
              color: Colors.greenAccent, size: 28),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    fetchSightMode(widget.docId).then((data) {
      setState(() {
        sightMode = data;
        isLoading = false;
      });
      assignPoints(sightMode!, updateAssignPointsState, context);
      addMarkers();
      setState(() => isDataLoaded = true);
    }).catchError((error) {
      setState(() => isLoading = false);
      debugPrint("Error fetching sight mode: $error");
    });

    getCurrentLocation();
    getDistanceAndDuration();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFF030A0E)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingIndicator(),
                const SizedBox(height: 20),
                const Text(
                  "Initializing Navigation",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (sightMode == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFF030A0E)),
          child: Center(
            child: Text(
              "Failed to load sight mode data.",
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ),
      );
    }

    if (!isDataLoaded || sourceLocation == null || destination == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFF030A0E)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingIndicator(),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Text(
                      "Source Location: ${sourceLocation ?? "Loading..."}",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    Text(
                      "Destination: ${destination ?? "Loading..."}",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                initialZoom: 15.5,
                onTap: (_, __) =>
                    setState(() => showDestinationInfo = false),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.practice',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylineCoordinates,
                      color: Colors.lightBlue,
                      strokeWidth: 6,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          Positioned(
            top: kToolbarHeight + 20,
            left: 20,
            right: 20,
            child: _buildGlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Instruction',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    navigationSteps.isNotEmpty &&
                            currentStepIndex < navigationSteps.length
                        ? "${navigationSteps[currentStepIndex]['instruction']} in ${navigationSteps[currentStepIndex]['distance'].toInt()}m"
                        : "You have arrived!",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildGlassPanel(
              child: Column(
                children: [
                  _buildInfoRow('Total Distance', distance),
                  _buildInfoRow('Estimated Duration', duration),
                  const Divider(color: Colors.white24),
                  _buildInfoRow('Next Waypoint Distance', waypointDistance),
                  _buildInfoRow('Next Waypoint ETA', waypointDuration),
                ],
              ),
            ),
          ),
          if (showDestinationInfo && currentpointDetails != null)
            AnimatedPositioned(
              duration: _animationDuration,
              top: kToolbarHeight + 140,
              left: 20,
              right: 190,
              child: AnimatedOpacity(
                duration: _animationDuration,
                opacity: showDestinationInfo ? 1.0 : 0.0,
                child: DestinationInfoBox(
                  name: currentpointDetails!['name'],
                  description: currentpointDetails!['description'],
                  imageurl: currentpointDetails!['imageUrls'][0],
                  onClose: () =>
                      setState(() => showDestinationInfo = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
