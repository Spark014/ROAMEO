// import 'package:flutter/material.dart';
// import 'package:google_maps_navigation/google_maps_navigation.dart';

// class NavigationSample extends StatefulWidget {
//   const NavigationSample({super.key});

//   @override
//   State<NavigationSample> createState() => _NavigationSampleState();
// }

// class _NavigationSampleState extends State<NavigationSample> {

//   GoogleNavigationViewController? _navigationViewController;
//   bool _navigationSessionInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeNavigationSession();
//   }

//   Future<void> _initializeNavigationSession() async {
//     if (!await GoogleMapsNavigator.areTermsAccepted()) {

//       await GoogleMapsNavigator.showTermsAndConditionsDialog(
//         'Example title',
//         'Example company',
//       );
//     }
//     // Note: make sure user has also granted location permissions before starting navigation session.
//     await GoogleMapsNavigator.initializeNavigationSession();
//     setState(() {
//       _navigationSessionInitialized = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Google Maps Navigation Sample')),
//       body: _navigationSessionInitialized
//           ? GoogleMapsNavigationView(
//               onViewCreated: _onViewCreated,
//               initialNavigationUIEnabledPreference: NavigationUIEnabledPreference.disabled,
//               // Other view initialization settings
//             )
//           : const Center(child: CircularProgressIndicator()),
//     );
//   }

//   void _onViewCreated(GoogleNavigationViewController controller) {
//     _navigationViewController = controller;
//     controller.setMyLocationEnabled(true);
//     // Additional setup can be added here.
//   }

//   @override
//   void dispose() {
//     if (_navigationSessionInitialized) {
//       GoogleMapsNavigator.cleanup();
//     }
//     super.dispose();
//   }
// }