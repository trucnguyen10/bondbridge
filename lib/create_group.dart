import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widget/user_image_picker_mobile.dart'
    if (dart.library.html) 'widget/user_image_picker_web.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController addUserController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  dynamic _pickedImage; // Can be File (mobile) or Uint8List (web)

  void _createGroup() async {
    final String groupName = groupNameController.text.trim();
    final String usernameToAdd = addUserController.text.trim();

    if (groupName.isEmpty || usernameToAdd.isEmpty || _pickedImage == null) {
      print('Group name, user to add, or image is empty');
      return;
    }

    try {
      // Check if user exists
      final userQuery = await _firestore
          .collection('userstorage')
          .where('username', isEqualTo: usernameToAdd)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('User does not exist');
        return;
      }

      // Create the group first without the photoUrl
      DocumentReference groupRef = await _firestore.collection('groups').add({
        'name': groupName,
        'members': [usernameToAdd], // Array of usernames or user IDs
        'photoUrl': '', // Placeholder, will be updated later
      });

      // Upload image to Firebase Storage
      String filePath = 'group_images/${groupRef.id}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      String imageUrl;
      if (kIsWeb) {
        await storageRef.putData(_pickedImage as Uint8List);
      } else {
        await storageRef.putFile(_pickedImage as File);
      }
      imageUrl = await storageRef.getDownloadURL();

      // Update group with the image URL
      await groupRef.update({'photoUrl': imageUrl});

      print('Group created with ID: ${groupRef.id}');
      Navigator.pop(context); // Go back after creating the group
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Center(
            child: Image.asset('assets/logo.png', height: 100),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Group Image Picker
            UserImagePicker(
              onPickImage: (pickedImage) {
                setState(() {
                  _pickedImage = pickedImage;
                });
              },
            ),
            SizedBox(height: 20),

            // Group Name Input Field
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Add User Text Field
            TextField(
              controller: addUserController,
              decoration: InputDecoration(
                labelText: 'Add User',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Create Group Button
            ElevatedButton(
              child: Text('Create Group'),
              onPressed: _createGroup,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    groupNameController.dispose();
    addUserController.dispose();
    super.dispose();
  }
}
