import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Home/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationCompletePage extends StatefulWidget {
  @override
  _RegistrationCompletePageState createState() =>
      _RegistrationCompletePageState();
}

class _RegistrationCompletePageState extends State<RegistrationCompletePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _username;
  String? _profileImageUrl;
  late Future<void> _fetchUserDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserDataFuture = _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found in Firestore');
      }

      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _username = data['username'] as String?;
        _profileImageUrl = data['profileImage'] as String?;
      });
    } catch (e) {
      _showSnackBar('Error fetching user data: $e');
    }
  }

  // Show snackbar message
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
          child: FutureBuilder(
            future: _fetchUserDataFuture,
            builder: (context, snapshot) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  _buildTitleSection(),
                  const SizedBox(height: 80),
                  _buildProfileImage(),
                  const SizedBox(height: 20),
                  _buildUsernameText(),
                  const SizedBox(height: 120),
                  _buildExploreButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Title Section
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Registration\nComplete",
          style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF44CAE9)),
        ),
        const SizedBox(height: 8),
        const Text(
          "Account has been created successfully",
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const Text(
          "Go where your heart roams",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  // Profile Image Section
  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5),
                BoxShadow(
                    color: Colors.lightBlueAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5),
              ],
            ),
          ),
          CircleAvatar(
            radius: 60,
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : const AssetImage('assets/profile_placeholder.png')
                    as ImageProvider,
          ),
        ],
      ),
    );
  }

  // Username Display
  Widget _buildUsernameText() {
    return Center(
      child: _username == null
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              _username!,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
    );
  }

  // Explore Button
  Widget _buildExploreButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF02202E),
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 10,
          shadowColor: Colors.blueAccent.withOpacity(0.5),
        ),
        child: const Text(
          "Explore Home",
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
