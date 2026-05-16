import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  //declare the google maps api key
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  ///declare other varuables needed for the simulation
  bool isLoading = true;
  static bool isDataLoaded = true;
  Map<String, dynamic>? sightMode;
  Set<LatLng> reachedNearWaypoints = {};
  Set<LatLng> reachedWaypoints = {};
  LatLng? reachedDestination;
  LatLng? reachedNearDestination;
  final String _connectionStatus = 'Unknown';
  final Completer<GoogleMapController> _controller = Completer();
  static LatLng? sourceLocation;
  static LatLng? destination;
  static List<LatLng> waypoints = [];
  List<Map<String, dynamic>> navigationSteps = [];
  int currentStepIndex = 0;
  static List<LatLng> polylineCoordinates = [];
  late List<PolylineWayPoint> activeWaypoints;
  LocationData? currentLocation;
  String distance = '';
  String duration = '';
  String waypointDistance = "";
  String waypointDuration = "";
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  Set<Marker> markers = {};
  String _mapStyle = '';
  bool showDestinationInfo = false;
  Map<String, dynamic>? currentpointDetails;
  final Duration _animationDuration = const Duration(milliseconds: 300);
  
  //reset the static variables
  void resetStaticVariables() {
    isDataLoaded = true;
    sourceLocation = null;
    destination = null;
    waypoints.clear();
    polylineCoordinates.clear();
  }
  
  //state to update the assign points
  void updateAssignPointsState(LatLng source, LatLng dest, List<LatLng> wps, bool loaded) {
    setState(() {
      sourceLocation = source;
      destination = dest;
      waypoints = wps;
      isDataLoaded = loaded;
    });
  }

  //dispose the state
  @override
  void dispose() {
    resetStaticVariables();
    super.dispose();
  }
  
  //set States of check proximity function
  void updateReachedNearWaypoints(LatLng waypoint) {
    setState(() {
      reachedNearWaypoints.add(waypoint);
    });
  }

  void updateReachedWaypoints(LatLng waypoint) {
    setState(() {
      reachedWaypoints.add(waypoint);
    });
  }

  void updateReachedDestination() {
    setState(() {
      reachedDestination = destination;
    });
  }

  void updateReachedNearDestination() {
    setState(() {
      reachedNearDestination = destination;
    });
  }
  
  //get the current location and set state
  void getCurrentLocation() async {
    Location location = Location();
    location.getLocation().then((location) {
      setState(() {
        currentLocation = location;
      });
      getPolyPoints();
    });
    
    //get the google map controller
    GoogleMapController googleMapController = await _controller.future;
    
    //listen to the location changes
    location.onLocationChanged.listen((newLoc) {
      setState(() {
        currentLocation = newLoc;
      });
      
      //add markers
      addMarkers();

      //trim the polyline
      trimPolyline(LatLng(newLoc.latitude!, newLoc.longitude!));
      
      //check proximity and notify
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

      //check if the location is within the polyline threshold
      LatLng currentLatLng = LatLng(newLoc.latitude!, newLoc.longitude!);
      if (!isLocationWithinPolylineThreshold(currentLatLng, polylineCoordinates, 50.0)) {
        getPolyPoints();
      }
      
      //get the distance and duration
      getWaypointDistanceandDuration(currentLocation, activeWaypoints[0]);
      //get the distance and duration
      getDistanceAndDuration();
      
      if (navigationSteps.isEmpty || currentStepIndex >= navigationSteps.length) {
        return;
      }
      

      LatLng userLatLng = LatLng(newLoc.latitude!, newLoc.longitude!);

      //calculate the distance to the next step
      double distanceToStep = calculateDistance(userLatLng, navigationSteps[currentStepIndex]['distance']);

      setState(() {
        navigationSteps[currentStepIndex]['distance'] = distanceToStep;
      });
      
      //check if the distance to the next step is less than 10
      if (distanceToStep < 10) {
        setState(() {
          currentStepIndex++;
        });
      }
      
      //animate the camera to the new location
      googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(newLoc.latitude!, newLoc.longitude!),
          zoom: 15.5,
        ),
      ));
    });
  }

  void getPolyPoints() async {

    //get the polyline points
    PolylinePoints polylinePoints = PolylinePoints();
    polylineCoordinates.clear();

    activeWaypoints = waypoints
        .where((wp) => !reachedWaypoints.contains(wp))
        .map((wp) => PolylineWayPoint(location: "${wp.latitude},${wp.longitude}"))
        .toList();
    
    //get the route between the coordinates
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiKey!,
      PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      PointLatLng(destination!.latitude, destination!.longitude),
      travelMode: TravelMode.driving,
      wayPoints: activeWaypoints,
      optimizeWaypoints: true,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> routePoints = [];
      for (var point in result.points) {
        routePoints.add(LatLng(point.latitude, point.longitude));
      }
      
      //set the state of the polyline coordinates
      setState(() {
        polylineCoordinates = routePoints;
      });
    }
  }

  //get the distance and duration
  Future<void> getDistanceAndDuration() async {
    LatLng currentLatLng = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
    String waypointsString = activeWaypoints.map((wp) => wp.location).join('|');
    
    //directions api url
    String url = waypointsString.isNotEmpty
        ? 'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${destination!.latitude},${destination!.longitude}&waypoints=optimize:true|$waypointsString&key=$apiKey'
        : 'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${destination!.latitude},${destination!.longitude}&key=$apiKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        var legs = data['routes'][0]['legs'];
        double totalDistance = 0;
        double totalDuration = 0;

        //get the total distance and duration
        for (var leg in legs) {
          totalDistance += leg['distance']['value'];
          totalDuration += leg['duration']['value'];
        }

        String distanceText = '${(totalDistance / 1000).toStringAsFixed(1)} km';
        String durationText = '${(totalDuration / 60).toStringAsFixed(0)} mins';

        setState(() {
          distance = distanceText;
          duration = durationText;
        });
      }
    }
  }
  
  //get the waypoint distance and duration
  Future<void> getWaypointDistanceandDuration(LocationData? currentLocation, PolylineWayPoint waypoint) async {
    LatLng currentLatLng = LatLng(currentLocation!.latitude!, currentLocation.longitude!);
    LatLng WaypointlatLng = LatLng(
      double.parse(waypoint.location.split(',')[0]),
      double.parse(waypoint.location.split(',')[1]),
    );
    
    //directions api url
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${WaypointlatLng.latitude},${WaypointlatLng.longitude}&mode=driving&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      //get distance and duration
      if (data['routes'].isNotEmpty) {
        final legs = data['routes'][0]['legs'][0];

        setState(() {
          waypointDistance = legs['distance']['text'];
          waypointDuration = legs['duration']['text'];
        });
        
        //filter the next steps
        List<Map<String, dynamic>> stepsList = [];
        for (var step in legs['steps']) {
          String instruction = step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
          double distance = step['distance']['value'].toDouble();

          stepsList.add({
            'instruction': instruction,
            'distance': distance,
          });
        }
        
        
        setState(() {
          navigationSteps = stepsList;
          currentStepIndex = 0;
        });
      }
    }
  }
  
  //function to trim the polyline
  void trimPolyline(LatLng userLocation) {
    if (polylineCoordinates.isEmpty) return;

    int closestIndex = findClosestPointIndex(userLocation, polylineCoordinates);

    setState(() {
      polylineCoordinates = polylineCoordinates.sublist(closestIndex);
    });
  }

//function to add markers
void addMarkers() async {
  markers.clear();

  if (sightMode == null || sightMode!['sights'] == null || sightMode!['sights'].isEmpty) {
    showAlertDialog2(context, "No sights available to display markers.");
    return;
  }

  List<dynamic> sights = sightMode!['sights'];

  if (waypoints.isEmpty) {
    showAlertDialog2(context, "No waypoints available to display markers.");
    return;
  }

  for (int i = 0; i < waypoints.length; i++) {
    if (i >= sights.length) {
      showAlertDialog2(context, "Waypoint index out of bounds.");
      continue;
    }

    var waypointDetails = sights[i];

    markers.add(
      Marker(
        markerId: MarkerId('waypoint_$i'),
        position: waypoints[i],
        infoWindow: InfoWindow(title:'Waypoint $i'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () async {
          // Zoom in on the tapped marker
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: waypoints[i],
                zoom: 18, 
              ),
            ),
          );

          //Show the DestinationInfoBox
          setState(() {
            showDestinationInfo = true;
            currentpointDetails = waypointDetails;
          });
        },
      ),
    );
  }

  if (destination != null && sights.isNotEmpty) {
    var destinationDetails = sights.last;
    int destinationId = sights.length - 1;

    markers.add(
      Marker(
        markerId: MarkerId('destination_$destinationId'),
        position: destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () async {
          // Zoom in on the tapped marker
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: destination!,
                zoom: 18, // Adjust the zoom level as needed
              ),
            ),
          );

          // Show the DestinationInfoBox
          setState(() {
            showDestinationInfo = true;
            currentpointDetails = destinationDetails;
          });
        },
      ),
    );
  }

  if (currentLocation != null) {
    markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        infoWindow: InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
  }
}
  //set init state with assigned points (sightMode)
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DefaultAssetBundle.of(context)
          .loadString('assets/map_styles/dark_mode.json')
          .then((string) {
        setState(() {
          _mapStyle = string;
        });
      });
    });
    
    //fetches the selected sightmode and call assignpoints function
    fetchSightMode(widget.docId).then((data) {
      setState(() {
        sightMode = data;
        isLoading = false;
      });
      assignPoints(sightMode!, updateAssignPointsState, context);
      addMarkers();
      setState(() {
        isDataLoaded = true;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching sight mode: $error");
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
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
              zoom: 15.5,
            ),
            markers: markers,
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.lightBlue,
                width: 6,
                zIndex: -1,
              )
            },
            onMapCreated: (mapController) {
              _controller.complete(mapController);
              mapController.setMapStyle(_mapStyle);
            },
            onTap: (_) {
              setState(() {
                showDestinationInfo = false;
              });
            },
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
                  navigationSteps.isNotEmpty && currentStepIndex < navigationSteps.length
                      ? "${navigationSteps[currentStepIndex]['instruction']} in ${navigationSteps[currentStepIndex]['distance'].toInt()}m"
                      : "You have arrived!",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
            top: kToolbarHeight + 140, // Position below the instructions bar
            left: 20,
            right: 190,
            child: AnimatedOpacity(
              duration: _animationDuration,
              opacity: showDestinationInfo ? 1.0 : 0.0,
              child: DestinationInfoBox(
                name: currentpointDetails!['name'],
                description: currentpointDetails!['description'],
                imageurl: currentpointDetails!['imageUrls'][0],
                onClose: () {
                  setState(() {
                    showDestinationInfo = false;
                  });
                },
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
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}