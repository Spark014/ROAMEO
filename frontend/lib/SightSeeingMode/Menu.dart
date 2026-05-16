import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:practice/SightSeeingMode/CameraPage/pages/camera_page.dart';
import 'package:practice/SightSeeingMode/Services/SightsSend.dart';
import 'package:practice/SightSeeingMode/Sightseeing_mode_page.dart';
import 'package:practice/SightSeeingMode/Simulation/pages/Ella_test.dart';
import 'package:practice/SightSeeingMode/Simulation/services/alertDialog.dart';
import 'package:practice/SightSeeingMode/location_select/models/location_info.dart';
import 'package:practice/SightSeeingMode/location_select/pages/autoCwidget.dart';
import 'package:practice/SightSeeingMode/CameraPage/providers/Image_provider.dart';
import 'package:practice/SightSeeingMode/location_select/providers/selected_place_provider.dart';
import 'package:practice/SightSeeingMode/models/sight.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:provider/provider.dart';
import 'package:practice/services/cloudinary_uploader.dart';
import 'dart:io';

//Make sure to import dart:io for File handling

class SightMenu extends StatefulWidget {
  const SightMenu({super.key});

  @override
  State<SightMenu> createState() => _SightMenuState();
}

class _SightMenuState extends State<SightMenu> {
  //Toggle switch state
  bool showLocations = true;
  
  //api key
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];


  Future<String> uploadImage(String filePath) async {
    try {
      return await CloudinaryUploader.uploadImage(File(filePath));
    } catch (e) {
      print("Error uploading image: $e");
      //Return local path if upload fails
      return filePath;
    }
  }

  void _deleteItem(dynamic item) {
    final selectedPlaceProvider =
        Provider.of<SelectedPlaceProvider>(context, listen: false);
    selectedPlaceProvider.removeItem(item);
  }

void _showEditDialog(BuildContext context, String title, int index) {
  TextEditingController _controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF030A0E).withOpacity(0.8),
          title: Text(
            "Edit $title",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new $title",
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                String enteredText = _controller.text.trim();
                if (enteredText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a value')),
                  );
                  return;
                }
                Provider.of<SelectedPlaceProvider>(context, listen: false)
                    .editItemByIndex(index, enteredText, title, context);
                Navigator.pop(context, enteredText);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showSaveDialog(BuildContext context) {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF030A0E).withOpacity(0.8),
          title: const Text(
            "Edit Sight Mode",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter Sight Mode Name",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Sight Mode Name",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter Description",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Description",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                String sightModeName = _nameController.text.trim();
                String description = _descriptionController.text.trim();
                if (sightModeName.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                print('Sight Mode Name: $sightModeName');
                print('Description: $description');
                Navigator.pop(context);
                onSightSave(sightModeName, description);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    },
  );
}


  onSightSave(String sightModeName, String sightDescription) async {
    
    final selectedPlaceProvider =
        Provider.of<SelectedPlaceProvider>(context, listen: false);

    final selectedImageProvider =
        Provider.of<SelectedImageProvider>(context, listen: false);


    //list to hold the Sightseeing mode object
    List<Sight> Sights = [];

    print("Selected Locations: ${selectedPlaceProvider.selectedLocations}");
    print("Selected Images: ${selectedImageProvider.selectedTrips}");

    //iterate through selected locations and create Sight objects
    for (var location in selectedPlaceProvider.selectedLocations) {
      if (location is LocationInfo) {
        Sight sight = Sight(
          modeName: sightModeName,
          modeDescription: sightDescription,
          username: "ROAMEO",
          id: DateTime.now()
              .millisecondsSinceEpoch
              .toString(), // Unique ID from the place API
          name: location.name,
          description: location.description,
          tags: location.tags, // You can modify this to add tags if needed
          lat: location.placeDetails.latitude,
          long: location.placeDetails.longitude,
          imageUrls: location.imageUrls.isNotEmpty ? location.imageUrls : [],
        );

        print(sight.toString());

        Sights.add(sight);
      }

      if (location is List<Map<String, dynamic>>) {
        //Extracting image URLs
        List<String> imagePaths = location
            .where((imageData) =>
                imageData.containsKey('photo') && imageData['photo'] != null)
            .map<String>((imageData) => imageData['photo'] as String)
            .toList();

        //store the uploaded Urls (jpgs uploaded to the firestorage and google map links)
        List<String> uploadedUrls = [];
        for (String path in imagePaths) {
          if (path.endsWith('.jpg')) {
            //upload the image to firestorage
            String downloadUrl = await uploadImage(path);

            //add the firestorage url to the uploaded urls
            uploadedUrls.add(downloadUrl);
          }
        }

        //Extract lat and long from the first image in the trip
        var firstImage = location.first;

        double? lat;
        double? long;

        if (firstImage.containsKey('latitude') &&
            firstImage.containsKey('longitude')) {
          lat = firstImage['latitude'] as double?;
          long = firstImage['longitude'] as double?;
        }

        //Extract name from the first image in the trip
        String? name;

        if (firstImage.containsKey('name')) {
          name = firstImage['name'] as String?;
        }

        //Extract tags from the first image in the trip
        List<String>? tags;

        if (firstImage.containsKey('tags')) {
          tags = firstImage['tags'] as List<String>?;
        }

        //Extract description from the first image in the trip
        String? description;

        if (firstImage.containsKey('description')) {
          description = firstImage['description'] as String?;
        }

        Sight sight = Sight(
          modeName: sightModeName,
          modeDescription: sightDescription,
          username: "ROAMEO",
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          tags: tags,
          lat: lat,
          long: long,
          imageUrls: uploadedUrls,
        );

        print(sight.toString());

        Sights.add(sight);
      }
    }

    //Print the entire Sights array after adding all objects
    print("Sights Array: $Sights");

    //After creating the Sights array
    sendSights(Sights);
  }

  
   @override
  Widget build(BuildContext context) {
    final selectedPlaceProvider = Provider.of<SelectedPlaceProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030A0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    selectedPlaceProvider.reorderTrips(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          color: Color(0xFF1E1E1E).withOpacity(0.9),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  children: selectedPlaceProvider.selectedLocations
                      .asMap()
                      .entries
                      .map<Widget>((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final key = ValueKey(item.hashCode);

                    return Container(
                      key: key,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xFF1E1E1E).withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: _buildListItem(item, index),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildFloatingButton(
            icon: Icons.search_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: PlacesAutoCompleteField(
                    apiKey: apiKey,
                  ),
                ),
              ),
            ),
          ),
          _buildFloatingButton(
            icon: Icons.camera_alt_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraPage()),
            ),
          ),
          _buildFloatingButton(
            icon: Icons.save,
            onPressed: () => _showSaveDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Align(
        alignment: Alignment.bottomRight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(icon, size: 28),
                color: Colors.white,
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildListItem(dynamic item, int index) {
  if (item is LocationInfo) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: item.imageUrls.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrls.first,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                onPressed: () => _showEditDialog(context, "Name", index),
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                onPressed: () => _deleteItem(item),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.description ?? "No description available",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                onPressed: () => _showEditDialog(context, "Description", index),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: item.tags.map((tag) => _buildTag(tag)).toList(),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showEditDialog(context, "Tag", index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white54),
                      SizedBox(width: 4),
                      Text(
                        'Add Tag',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  } else if (item is List<Map<String, dynamic>>) {
    final firstItem = item.isNotEmpty ? item.first : null;
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: firstItem != null && firstItem.containsKey('photo')
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(firstItem['photo']),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  firstItem?['name'] ?? 'Image Collection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                onPressed: () => _showEditDialog(context, "Name", index),
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                onPressed: () => _deleteItem(item),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  firstItem?['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                onPressed: () => _showEditDialog(context, "Description", index),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstItem != null && firstItem.containsKey('tags'))
                Wrap(
                  spacing: 6,
                  children: (firstItem['tags'] as List<dynamic>)
                      .map<Widget>((tag) => _buildTag(tag.toString()))
                      .toList(),
                ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showEditDialog(context, "Tag", index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white54),
                      SizedBox(width: 4),
                      Text(
                        'Add Tag',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  return const ListTile(
    title: Text("Unknown item", style: TextStyle(color: Colors.white)),
  );
}

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100]?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: Colors.blue[200],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}