import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:practice/SightSeeingMode/Feed/SightFeed.dart';
import 'package:practice/SightSeeingMode/Menu.dart';

class SsmPage extends StatefulWidget {
  const SsmPage({super.key});

  @override
  _SsmPageState createState() => _SsmPageState();
}

class _SsmPageState extends State<SsmPage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _showDetails = false;
  String _selectedScenery = 'temporary';
  LatLng? _initialCenter;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _loadMarkers();
  }

  Future<void> _loadCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() {
      _initialCenter = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _loadMarkers() {
    setState(() {
      _markers.addAll([
        _buildMarker(const LatLng(37.425, -122.08), 'temporary'),
        _buildMarker(const LatLng(37.42, -122.085), 'permanent'),
      ]);
    });
  }

  Marker _buildMarker(LatLng position, String type) {
    final color = type == 'temporary'
        ? Colors.lightBlueAccent
        : Colors.cyanAccent;
    return Marker(
      point: position,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => setState(() => _showDetails = true),
        child: Icon(Icons.location_on, color: color, size: 44),
      ),
    );
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(_buildMarker(position, _selectedScenery));
    });
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF030A0E).withOpacity(0.8),
            title: const Text("Select Scenery Type",
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Temporary",
                      style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    fillColor: WidgetStateColor.resolveWith(
                        (states) => Colors.blue),
                    value: "temporary",
                    groupValue: _selectedScenery,
                    onChanged: (value) =>
                        _updateScenery(value.toString(), context),
                  ),
                ),
                ListTile(
                  title: const Text("Permanent",
                      style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    fillColor: WidgetStateColor.resolveWith(
                        (states) => Colors.cyan),
                    value: "permanent",
                    groupValue: _selectedScenery,
                    onChanged: (value) =>
                        _updateScenery(value.toString(), context),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Confirm",
                    style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateScenery(String value, BuildContext context) {
    setState(() => _selectedScenery = value);
    Navigator.pop(context);
  }

  void _resetBearing() {
    _mapController.rotate(0);
  }

  Future<void> _goToCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    _mapController.move(LatLng(pos.latitude, pos.longitude), 18);
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCenter == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF030A0E),
        body: Center(
          child: CircularProgressIndicator(color: Colors.lightBlue),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!,
              initialZoom: 14,
              onTap: (tapPosition, latLng) => _addMarker(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.practice',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black.withOpacity(0.3),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 80,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Search locations...",
                              hintStyle: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                          onPressed: () {},
                          splashRadius: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlassButton(
                  icon: Icons.explore,
                  onPressed: _resetBearing,
                ),
                const SizedBox(height: 15),
                _buildGlassButton(
                  icon: Icons.my_location,
                  onPressed: _goToCurrentLocation,
                ),
              ],
            ),
          ),
          if (_showDetails)
            GestureDetector(
              onTap: () => setState(() => _showDetails = false),
              behavior: HitTestBehavior.opaque,
            ),
          if (_showDetails)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF030A0E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Beautiful Scenery",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () =>
                                setState(() => _showDetails = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Image.asset('assets/images/rectangle 24.png'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.5),
                              Colors.cyan.withOpacity(0.5),
                            ],
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("EXPLORE",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildGlassButton(
                  icon: Icons.add_location,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SightMenu()),
                  ),
                ),
                const SizedBox(width: 15),
                _buildGlassButton(
                  icon: Icons.list,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SightFeed()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              icon: Icon(icon, color: Colors.white),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
