import 'package:flutter/material.dart';
import 'package:practice/features/tour_mode/services/alertDialog.dart';
import 'package:practice/SightSeeingMode/location_select/models/autoCmodal.dart';
import 'package:practice/SightSeeingMode/location_select/models/location_info.dart';

//Holding all the selected location object in an array
class SelectedPlaceProvider with ChangeNotifier {
  List<dynamic> _selectedLocations = [];

  List<dynamic> get selectedLocations => _selectedLocations;

  //set the combined location object and add it to the array
  void addLocationInfo(LocationInfo locationInfo) {
    locationInfo.toString();

    _selectedLocations.add(locationInfo);

    print(selectedLocations);

    notifyListeners();
  }

  //set the combined image object and add it to the array
  void addImageInfo(List<Map<String, dynamic>> tripData) {
    print(tripData);

    _selectedLocations.add(tripData);

    print(selectedLocations);

    notifyListeners();
  }

  //Reorder the items
  void reorderTrips(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final trip = _selectedLocations.removeAt(oldIndex);

    _selectedLocations.insert(newIndex, trip);

    notifyListeners();
  }

  void removeItem(dynamic item) {
    // Remove the item from the list
    _selectedLocations.remove(item);

    print("item removed");

    print(selectedLocations);

    // Notify listeners to update the UI
    notifyListeners();
  }

  void editItemByIndex(
      int index, String text, String title, BuildContext context) {
    if (index >= 0 && index < _selectedLocations.length) {
      if (title == "Name") {
        //If the object is LocationInfo
        if (_selectedLocations[index] is LocationInfo) {
          (_selectedLocations[index] as LocationInfo).name = text;
        } else if (_selectedLocations[index] is List<Map<String, dynamic>>) {
          //Update the first entry for image data as an example
          _selectedLocations[index][0]['name'] = text;
        }
      } else if (title == "Description") {
        //Handle description editing if needed
        if (_selectedLocations[index] is LocationInfo) {
          (_selectedLocations[index] as LocationInfo).description = text;
          print((_selectedLocations[index] as LocationInfo).description);
        } else if (_selectedLocations[index] is List<Map<String, dynamic>>) {
          _selectedLocations[index][0]['description'] = text;
        }
      } else if (title == "Tag") {
        if (_selectedLocations[index] is LocationInfo) {
          (_selectedLocations[index] as LocationInfo).tags.add(text);
        } else if (_selectedLocations[index] is List<Map<String, dynamic>>) {
          //Ensure the 'tags' key exists in the first map of the list
          if (!_selectedLocations[index][0].containsKey('tags')) {
            //If 'tags' key doesn't exist, initialize it as an empty list
            _selectedLocations[index][0]['tags'] = [];
          }
          //Add the new tag to the list
          (_selectedLocations[index][0]['tags'] as List).add(text);
        }
      }

      notifyListeners(); // Notify UI about the change
    } else {
      print("Invalid index: $index");
    }
  }
}
