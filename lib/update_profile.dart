// update_profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Add this line
import 'models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'dart:typed_data';
import 'dart:io'; // Add this for File type
import '../widget/user_image_picker_mobile.dart'
    if (dart.library.html) 'widget/user_image_picker_web.dart';
import '../widget/update.dart';

class UpdateProfilePage extends StatefulWidget {
  final String userId;

  const UpdateProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String _name = '';
  String _username = '';
  dynamic _pickedImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userstorage')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        var userModel =
            UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        setState(() {
          _name = userModel.name;
          _username = userModel.username;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        String imageUrl = '';
        if (_pickedImage != null) {
          String filePath = 'user_images/${widget.userId}.jpg';
          Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

          if (kIsWeb) {
            await storageRef.putData(_pickedImage as Uint8List);
          } else {
            await storageRef.putFile(_pickedImage as File);
          }
          imageUrl = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance
            .collection('userstorage')
            .doc(widget.userId)
            .update({
          'name': _name,
          'username': _username,
          if (_pickedImage != null) 'image_url': imageUrl,
        });

        Navigator.pop(context, true);
        // Return true after update
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_pickedImage != null)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: FileImage(_pickedImage),
                ),
              UpdateUserImagePicker(
                updateImage: (pickedImage) {
                  setState(() {
                    _pickedImage = pickedImage;
                  });
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (value) => _name = value!,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                onSaved: (value) => _username = value!,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _updateUserProfile,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
