import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadPhotoPage extends StatefulWidget {
  final String groupId;

  UploadPhotoPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _UploadPhotoPageState createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        String fileName =
            'group_photos/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        await storageRef.putFile(_image!);
        String downloadURL = await storageRef.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('photos')
            .add({'url': downloadURL});

        print('Upload complete');
      } catch (e) {
        print('Error occurred while uploading: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Photo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image != null ? Image.file(_image!) : Text('No image selected'),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
