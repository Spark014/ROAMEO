import 'dart:ui';
import 'package:flutter/material.dart';

class PlacesAutoCompleteField extends StatelessWidget {
  final String? apiKey;
  final String? hint;
  final double? latitude;
  final double? longitude;
  final int? radius;
  final String? types;

  const PlacesAutoCompleteField({
    Key? key,
    required this.apiKey,
    this.hint,
    this.latitude,
    this.longitude,
    this.radius,
    this.types,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A0E),
      body: SafeArea(
        child: Stack(
          children: [
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
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore,
                            color: Colors.white70, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Place search coming back soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Autocomplete is temporarily disabled while we '
                          'swap providers. Pin spots manually for now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
