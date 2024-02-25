import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({
    super.key,
    required this.onPickImage,
  });

  final void Function(File pickedImage) onPickImage;

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImageFile;

  // Function to handle image picking
  void _pickImage() async {
    print("Image Picker Triggered"); // Debugging print
    final pickedImageFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    if (pickedImageFile == null) {
      print("No image selected"); // Debugging print
      return;
    }

    if (pickedImageFile != null) {
      print("Image selected"); // Debugging print
      print("file path: " + pickedImageFile.path); // Debugging print
    }

    setState(() {
      _pickedImageFile = File(pickedImageFile.path);
    });

    widget.onPickImage(_pickedImageFile!);
    print(_pickedImageFile); // Debugging print
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40, // Size of the avatar
          backgroundColor: Colors.grey,
          // If an image is picked, display it, otherwise show grey background
          backgroundImage:
              _pickedImageFile != null ? FileImage(_pickedImageFile!) : null,
        ),
        TextButton.icon(
          onPressed: _pickImage, // Trigger image picking on press
          icon: const Icon(Icons.image), // Icon for the button
          label: Text(
            'Add Image',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .primary, // Use primary color from the theme
            ),
          ),
        )
      ],
    );
  }
}
