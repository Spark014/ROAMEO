import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'Register_Completion_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:practice/services/cloudinary_uploader.dart';

// Stateful widget to setting up user account
class SetupAccountPage extends StatefulWidget {
  const SetupAccountPage({super.key});

  @override
  _SetupAccountPageState createState() => _SetupAccountPageState();
}

class _SetupAccountPageState extends State<SetupAccountPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      _showSnackBar('Please select an image');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Not signed in. Please log in again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String downloadURL =
          await CloudinaryUploader.uploadImage(_image!);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({'profileImage': downloadURL}, SetOptions(merge: true));

      // Navigate to Registration Completion Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationCompletePage()),
      );
    } catch (e) {
      debugPrint("Error uploading image: $e");
      _showSnackBar('Error: $e'); // Error message
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  /// Display snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 40),
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white60, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                "Setup your\n account",
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF44CAE9)),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                "Finish your account setup by uploading your profile picture.",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 25),

              // Profile Image Picker
              _buildProfileImagePicker(),

              const SizedBox(height: 40),

              // Create Account Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadImage, // button disable
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02202E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 110, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white) // Loadng spinner
                      : const Text(
                          "Create account",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile image selection widget
  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundImage: _image != null
                ? FileImage(_image!)
                : const AssetImage('assets/profile_placeholder.png')
                    as ImageProvider,
          ),

          // Camera icon
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.5), blurRadius: 5)
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
