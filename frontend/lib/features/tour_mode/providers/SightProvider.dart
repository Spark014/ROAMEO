//To store and provide the sight object that's currently running
import 'package:flutter/material.dart';
import 'package:practice/features/tour_mode/services/alertDialog.dart';

class SightProvider with ChangeNotifier {
  //array to hold sights
  List<dynamic> _sights = [];

  //Getter for the sights list
  List<dynamic> get sights => _sights;

  //Method to update the sights list
  void setSights(List<dynamic> sights) {
    _sights = sights;
    notifyListeners(); //Notify listeners to rebuild widgets
  }

  //Method to get a specific sight by index
  void getSight(BuildContext context, int index) {
  if (index >= 0 && index < _sights.length) {
    // Example usage of context in the alert dialog
    showAlertDialog2(context, "Sight found: ${_sights[index]['modeName']}");
  } else {
    showAlertDialog2(context, "Invalid index");
  }
 }
}
