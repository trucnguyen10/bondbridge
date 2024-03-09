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

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _userModel;

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
    return Scaffold(
      backgroundColor: Color(0xFFFFF7F1),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.logout, size: 24.0), // Sign-out icon
          onPressed: () {
            FirebaseAuth.instance.signOut();
          },
        ),
        title: Image.asset('assets/logo.png', height: 100),
        actions: [
          IconButton(
            icon: Icon(Icons.home, size: 40.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupsPage()),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Center(
        child: _userModel == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Name: ${_userModel!.name}',
                      style: GoogleFonts.anton(
                          fontSize: 30, color: Color(0xffe78895))),
                  SizedBox(height: 10),
                  Text('Username: ${_userModel!.username}',
                      style: GoogleFonts.anton(
                          fontSize: 20, color: Color(0xffBED1CF))),
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_userModel!.imageUrl),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UpdateProfilePage(userId: widget.userId),
                        ),
                      );

                      // Debugging print statement
                      print("Update result: $result");

                      if (result == true) {
                        _fetchUserData();
                      }
                    },
                    child: Text('Edit Profile'),
                  ),
                ],
              ),
      ),
    );
  }
}
