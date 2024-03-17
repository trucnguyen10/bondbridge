import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'dart:typed_data';
import 'dart:io';
import 'update_profile.dart'; // Ensure this file exists with correct implementation
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'mood_picker.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _userModel;
  Mood? _selectedMood;
  Map<String, Color> moodColors = {
    'Sad': Color.fromARGB(255, 143, 191, 244),
    'Inlove': Color.fromARGB(255, 240, 154, 183),
    'Happy': Color.fromARGB(255, 124, 225, 210),
    'Sleepy': Color.fromARGB(255, 200, 161, 230),
    'Surprise': Color.fromARGB(255, 234, 205, 164),
    // Add more moods and their corresponding colors here
  };

  // Method to get color based on mood
  Color _getMoodColor(String moodName) {
    return moodColors[moodName] ??
        Color(0xFFFFF7F1); // Default color if mood not found
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userstorage')
          .doc(widget.userId)
          .get();

      print('userDoc');
      print(userDoc);
      print(userDoc.data());

      if (userDoc.exists) {
        setState(() {
          _userModel =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        });
      } else {
        print('User document does not exist for userId: ${widget.userId}');
        // Handle the case where the user document does not exist
        // For example, navigate back or show a message
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Handle any other errors
    }
  }

  @override
  void initState() {
    print('initState');
    super.initState();
    _fetchUserData();
  }

  void _navigateAndDisplayMoodSelection(BuildContext context) async {
    final result = await Navigator.push<Mood>(
      context,
      MaterialPageRoute(builder: (context) => MoodPickerPage()),
    );

    if (result != null) {
      setState(() {
        _selectedMood = result;
      });

      // Update the mood in Firestore
      await FirebaseFirestore.instance
          .collection('userstorage')
          .doc(widget.userId)
          .update({'mood': result.name});
    }
  }

  Future<void> _updateProfilePicture(dynamic pickedImage) async {
    // Upload the new image and get the URL
    String filePath = 'user_images/${widget.userId}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

    if (kIsWeb) {
      await storageRef.putData(pickedImage as Uint8List);
    } else {
      await storageRef.putFile(pickedImage as File);
    }
    String newImageUrl = await storageRef.getDownloadURL();

    // Update Firestore with the new image URL
    await FirebaseFirestore.instance
        .collection('userstorage')
        .doc(widget.userId)
        .update({'image_url': newImageUrl});

    // Update local state
    if (_userModel != null) {
      setState(() {
        _userModel!.imageUrl = newImageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = _selectedMood != null
        ? _getMoodColor(_selectedMood!.name)
        : Color(0xFFFFF7F1); // Default color if no mood is selected

    return Scaffold(
      backgroundColor: backgroundColor, // Set the dynamic background color
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
        title: Image.asset('assets/logo.png', height: 100),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GroupsPage()),
            ),
          ),
        ],
      ),
      body: Center(
        child: _userModel == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Name: ${_userModel!.name}',
                      style: GoogleFonts.anton(
                          fontSize: 30, color: Color.fromARGB(255, 8, 6, 6))),
                  SizedBox(height: 10),
                  Text('Username: ${_userModel!.username}',
                      style: GoogleFonts.anton(
                          fontSize: 20, color: Color.fromARGB(255, 9, 13, 13))),
                  SizedBox(height: 20),
                  CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_userModel!.imageUrl)),
                  SizedBox(height: 20),
                  if (_selectedMood != null) // Display the selected mood
                    Column(
                      children: [
                        Image.asset(_selectedMood!.imagePath, height: 50),
                        Text('Mood: ${_selectedMood!.name}'),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () => _navigateAndDisplayMoodSelection(context),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFFFD4D4), // Background color
                      onPrimary: Colors.black, // Text color
                    ),
                    child: Text('Set Your Mood'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                UpdateProfilePage(userId: widget.userId)),
                      );
                      if (result == true) _fetchUserData();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFFFD4D4), // Background color
                      onPrimary: Colors.black, // Text color
                    ),
                    child: Text('Edit Profile'),
                  ),
                ],
              ),
      ),
    );
  }
}
