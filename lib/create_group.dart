import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  dynamic _pickedImage; // Can be File (mobile) or Uint8List (web)

  void _createGroup() async {
    final String groupName = groupNameController.text.trim();
    final String currentUserId = _auth.currentUser?.uid ?? '';
    final List<String> usernamesToAdd = addUserController.text
        .trim()
        .split(',')
        .map((username) => username.trim())
        .where((username) => username.isNotEmpty)
        .toList();

    if (groupName.isEmpty || _pickedImage == null || currentUserId.isEmpty) {
      print('Group name or image is empty, or user is not logged in');
      return;
    }

    try {
      List<String> userIds = [currentUserId]; // Include the group creator
      for (String username in usernamesToAdd) {
        var userQuery = await _firestore
            .collection('userstorage')
            .where('username', isEqualTo: username)
            .get();

        if (userQuery.docs.isNotEmpty) {
          userIds.add(userQuery.docs.first.id);
        } else {
          print('User not found: $username');
        }
      }

      DocumentReference groupRef = await _firestore.collection('groups').add({
        'name': groupName,
        'members': userIds,
        'photoUrl': '', // Placeholder, will be updated later
      });

      await _uploadGroupImageAndUpdate(groupRef);
      print('Group created with ID: ${groupRef.id}');
      Navigator.pop(context); // Go back after creating the group
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  Future<void> _uploadGroupImageAndUpdate(DocumentReference groupRef) async {
    String filePath = 'group_images/${groupRef.id}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
    String imageUrl;

    if (kIsWeb) {
      await storageRef.putData(_pickedImage as Uint8List);
    } else {
      await storageRef.putFile(_pickedImage as File);
    }
    imageUrl = await storageRef.getDownloadURL();
    await groupRef.update({'photoUrl': imageUrl});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Image.asset('assets/logo.png', height: 100)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home, size: 40.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserImagePicker(
              onPickImage: (pickedImage) {
                setState(() {
                  _pickedImage = pickedImage;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: addUserController,
              decoration: InputDecoration(
                labelText: 'Add Users (comma-separated)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createGroup,
              child: Text('Create Group'),
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
