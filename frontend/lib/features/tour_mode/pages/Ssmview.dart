import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:practice/SightSeeingMode/Ella%20details/Ella_route.dart';
import 'package:practice/SightSeeingMode/Services/SightGet.dart';
import 'package:practice/features/tour_mode/models/DetailWidget.dart';
import 'package:practice/features/tour_mode/pages/Navigation.dart';
import 'package:practice/features/tour_mode/pages/mapbox.dart';
import 'package:practice/features/tour_mode/providers/SightProvider.dart';
import 'package:practice/features/tour_mode/services/Haversine_formula.dart';
import 'package:practice/features/tour_mode/services/TrimPolyline.dart';
import 'package:practice/features/tour_mode/services/assignPoints.dart';
import 'package:practice/features/tour_mode/services/alertDialog.dart';
import 'package:practice/features/tour_mode/services/checkProximity.dart';
import 'package:practice/features/tour_mode/services/PolylineThresholdCheck.dart';
import 'package:practice/features/tour_mode/services/readCoordinatesfromfile.dart';

class SsmView extends StatefulWidget {
  //widget takes the index as a parameter to figure out the sightseeing mode id
  final int index;

  //widget takes the doc id of the sight
  final String docId;

  const SsmView({super.key, required this.index, required this.docId});

  @override
  State<SsmView> createState() => SsmViewState();
}

class SsmViewState extends State<SsmView> {
  //map styles 
  String _mapStyle= "";
  //animation duration 
  final Duration _animationDuration = const Duration(milliseconds: 300);
  //api key
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  //loading state variable
  bool isLoading = true;

  //Add a flag to track if data is loaded
  static bool isDataLoaded = true;

  //store the recieved sightseeing data in a Map
  Map<String, dynamic>? sightMode;

  //Store reached near waypoints to avoid duplicate alerts (when you are near a waypoint)
  Set<LatLng> reachedNearWaypoints = {};

  //Store reached waypoints to avoid duplicate alerts (when you reached a waypoint)
  Set<LatLng> reachedWaypoints = {};

  //reached destination to avoid duplicate alerts
  LatLng? reachedDestination;

  //reached near destination
  LatLng? reachedNearDestination;

  //track the internet connection status
  final String _connectionStatus = 'Unknown';

  //Google map instance as a completer
  final Completer<GoogleMapController> _controller = Completer();

  //temporary holders for the sourcelocation and destination
  static LatLng? sourceLocation;
  static LatLng? destination;
  static List<LatLng> waypoints = [];

  //store the navigation steps recieved from the Directions waypoint api request
  List<Map<String, dynamic>> navigationSteps = [];

  //track the current step
  int currentStepIndex = 0;

  //list of lat and lang co-ordinates to hold the polyline coordinates
  static List<LatLng> polylineCoordinates = [];

  //define only the active way points
  late List<PolylineWayPoint> activeWaypoints;

  //stores the current location as in lat and lang (Location package)
  LocationData? currentLocation;

  //distance and duration holders (for the distanced matrix api response)
  String distance = '';
  String duration = '';

  //distance and duration holders (for the direction api request for waypoints)
  String waypointDistance = "";
  String waypointDuration = "";

  //custom marker variables (Bitmap descriptor)
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  //Set to hold markers
  Set<Marker> markers = {};

  bool showDestinationInfo = false;

  //current point detais
  Map<String, dynamic>? currentpointDetails;

  //polylyline variables 
  bool isFetchingPolyline = false;

  // Method to reset static variables
  void resetStaticVariables() {
    isDataLoaded = true;
    sourceLocation = null;
    destination = null;
    waypoints.clear();
    polylineCoordinates.clear();
  }

  //setState of assignPoints function
  void updateAssignPointsState(
    LatLng source,
    LatLng dest,
    List<LatLng> wps,
    bool loaded,
  ) {
    setState(() {
      sourceLocation = source;
      destination = dest;
      waypoints = wps;
      isDataLoaded = loaded;
    });
  }

  @override
  void dispose() {
    resetStaticVariables(); // Reset static variables when the widget is disposed
    super.dispose();
  }

  //functions to keep track of reached waypoints and destinations
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

  //function to get the current location (using the location package)
  void getCurrentLocation() async {
    //hold the current location
    Location location = Location();
    //get the current location using getlocation and uses then to handle the result (Location package)
    location.getLocation().then(
      (location) {
        setState(() {
          //set the current location to the obtained location
          currentLocation = location;
        });
        //call getPolyPoints after a obtaining the current location
        getPolyPoints();
      },
    );

    //waits for the google map controller to be available
    GoogleMapController googleMapController = await _controller.future;
  }

  //function to get the polypoints
void getPolyPoints() async {
  if (isFetchingPolyline) return;
  isFetchingPolyline = true;

  if (sourceLocation == null || destination == null) {
    print("Source or destination is null. Cannot fetch polyline.");
    isFetchingPolyline = false;
    return;
  }

  PolylinePoints polylinePoints = PolylinePoints();
  polylineCoordinates.clear();

  activeWaypoints = waypoints
      .where((wp) => !reachedWaypoints.contains(wp))
      .map((wp) => PolylineWayPoint(location: "${wp.latitude},${wp.longitude}"))
      .toList();

  var sightModeFirst = sightMode!['sights'][0];
  String sightModeName = sightModeFirst['modeName'];

  if (sightModeName == "Ella-Odyssey-Left" || sightModeName == "Ella-Odyssey-Right") {
    setState(() {
      polylineCoordinates = [...EllaroutePoints];
    });
  } else {
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        apiKey!,
        PointLatLng(sourceLocation!.latitude, sourceLocation!.longitude),
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

        setState(() {
          polylineCoordinates = routePoints;
        });
      } else {
        print("No points returned from the API.");
      }
    } catch (e) {
      print("Error fetching polyline: $e");
    }
  }

  isFetchingPolyline = false;
}
  //call set state which has many functions
  // setState(() {});

  //distance matrix api request for the sightseeing route
  Future<void> getDistanceAndDuration() async {
    //convert current location into a lat lang object
    LatLng currentLatLng =
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

    //Prepare the waypoints string for the Directions API request
    String waypointsString = activeWaypoints.map((wp) => wp.location).join('|');

    //Directions API URL with current location, destination, and waypoints
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${destination!.latitude},${destination!.longitude}&waypoints=optimize:true|$waypointsString&key=$apiKey';

    //get request to distance matrix api
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        //Extract the total distance and duration from the first route
        var legs = data['routes'][0]['legs'];
        double totalDistance = 0;
        double totalDuration = 0;

        for (var leg in legs) {
          totalDistance += leg['distance']['value'];
          totalDuration += leg['duration']['value'];
        }

        //Convert distance to kilometers and duration to minutes
        String distanceText = '${(totalDistance / 1000).toStringAsFixed(1)} km';
        String durationText = '${(totalDuration / 60).toStringAsFixed(0)} mins';

        //call set state
        setState(() {
          distance = distanceText;
          duration = durationText;
        });
      } else {
        print("Failed to get distance and duration");
      }
    }
  }

  //distance and duration to the nearest waypoint using directions api*
  Future<void> getWaypointDistanceandDuration(
      LocationData? currentLocation, PolylineWayPoint waypoint) async {
    //convert current location into a lat lang object
    LatLng currentLatLng =
        LatLng(currentLocation!.latitude!, currentLocation.longitude!);

    //convert the PolylineWaypoint object into a lat lang object
    LatLng WaypointlatLng = LatLng(
      double.parse(waypoint.location.split(',')[0]),
      double.parse(waypoint.location.split(',')[1]),
    );

    //directions api request
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${WaypointlatLng.latitude},${WaypointlatLng.longitude}&mode=driving&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final legs = data['routes'][0]['legs'][0];

        setState(() {
          waypointDistance = legs['distance']['text'];
          waypointDuration = legs['duration']['text'];
        });

        print('Distance: $waypointDistance, Duration: $waypointDuration');

        //Extract step-by-step navigation instructions
        List<Map<String, dynamic>> stepsList = [];
        for (var step in legs['steps']) {
          //Remove HTML tags
          String instruction =
              step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
          //Distance in meters
          double distance = step['distance']['value'].toDouble();

          stepsList.add({
            'instruction': instruction,
            'distance': distance,
          });
        }
        //Store navigation steps
        setState(() {
          navigationSteps = stepsList;
          //Start from first step
          currentStepIndex = 0;
        });

        print("Navigation Steps: $navigationSteps");
      } else {
        print("Failed to fetch waypoint distance & duration.");
      }
    }
  }

 // Function to add markers for waypoints and destination
void addMarkers() {
  markers.clear();

  // Ensure sightMode and sights are not null or empty
  if (sightMode == null ||
      sightMode!['sights'] == null ||
      sightMode!['sights'].isEmpty) {
    showAlertDialog2(context, "No sights available to display markers.");
    return;
  }

  List<dynamic> sights = sightMode!['sights'];

  // Add markers for waypoints
  for (int i = 0; i < sights.length - 1; i++) {
    // Exclude the last element (destination)
    var waypoint = sights[i];

    markers.add(
      Marker(
        markerId: MarkerId('waypoint_$i'),
        position: LatLng(waypoint['lat'], waypoint['long']),
        infoWindow: InfoWindow(title: waypoint['description']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () async {
          // Zoom in on the tapped marker
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(waypoint['lat'], waypoint['long']), // Use waypoint coordinates
                zoom: 18, // Adjust the zoom level as needed
              ),
            ),
          );

          setState(() {
            showDestinationInfo = true;
            currentpointDetails = waypoint;
          });
        },
      ),
    );
  }

  // Add marker for destination
  var destinationDetails = sights.last; // Last element is the destination
  int destinationId = sights.length - 1; // Correct index for the destination

  markers.add(
    Marker(
      markerId: MarkerId('destination_$destinationId'),
      position: LatLng(destinationDetails['lat'], destinationDetails['long']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onTap: () async {
        // Zoom in on the tapped marker
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(destinationDetails['lat'], destinationDetails['long']), // Use destination coordinates
              zoom: 18, // Adjust the zoom level as needed
            ),
          ),
        );

        setState(() {
          showDestinationInfo = true;
          currentpointDetails = destinationDetails;
        });
      },
    ),
  );

  // Log markers for debugging
  print("Markers added: ${markers.length}");
}


   //init state
  @override
  void initState() {
    super.initState();
    
    // Load map style
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DefaultAssetBundle.of(context)
          .loadString('assets/map_styles/dark_mode.json')
          .then((string) {
        setState(() {
          _mapStyle = string;
        });
      });
    });
    
    // Fetch sight mode data
    fetchSightMode(widget.docId).then((data) {
      setState(() {
        sightMode = data;
        isLoading = false; // Data fetched, set loading to false
        print("sightMode: $sightMode");
      });
      assignPoints(sightMode!, updateAssignPointsState, context);
      addMarkers();
      setState(() {
        isDataLoaded = true;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false; // Error occurred, set loading to false
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
                "Loading Route Preview",
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

  // Show loading indicator until sourceLocation and destination are initialized
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
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Route Preview",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: sourceLocation!, // Center map on the source location
            zoom: 16, // Adjust zoom level for better visibility
          ),
          markers: markers, // Display markers for waypoints and destination
          polylines: {
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylineCoordinates, // Display the route
              color: Colors.lightBlue, // Route color
              width: 6, // Route thickness
            ),
          },
          onMapCreated: (mapController) {
            _controller.complete(mapController); // Initialize map controller
            mapController.setMapStyle(_mapStyle); // Apply the dark mode style
          },
          onTap: (_) {
            setState(() {
              showDestinationInfo = false; // Hide info on map tap
            });
          },
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
              ],
            ),
          ),
        ),
        if (showDestinationInfo && currentpointDetails != null)
          AnimatedPositioned(
            duration: _animationDuration,
            top: kToolbarHeight + 20,
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
                    showDestinationInfo = false; // Hide info box on close
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