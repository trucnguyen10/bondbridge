import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class UpdateUserImagePicker extends StatefulWidget {
  final void Function(dynamic pickedImage) updateImage;

  const UpdateUserImagePicker({Key? key, required this.updateImage})
      : super(key: key);

  @override
  _UpdateUserImagePickerState createState() => _UpdateUserImagePickerState();
}

class _UpdateUserImagePickerState extends State<UpdateUserImagePicker> {
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
      widget.updateImage(_pickedImageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_pickedImageFile != null) {
      imageProvider = FileImage(_pickedImageFile!);
    }

    print('imageProvider');
    print(imageProvider);

    return Column(
      children: [
        TextButton.icon(
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text('Update Image'),
        ),
      ],
    );
  }
}
