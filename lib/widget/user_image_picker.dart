import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

class UserImagePicker extends StatefulWidget {
  final void Function(dynamic pickedImage) onPickImage;

  const UserImagePicker({Key? key, required this.onPickImage})
      : super(key: key);

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;

  void _pickImage() async {
    if (kIsWeb) {
      // Web-specific logic
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
        ..accept = 'image/*';
      uploadInput.accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final file = uploadInput.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _pickedImageBytes = reader.result as Uint8List;
          });
          widget.onPickImage(_pickedImageBytes);
        });
      });
    } else {
      // Mobile image picking logic
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (kIsWeb) {
      if (_pickedImageBytes != null) {
        imageProvider = MemoryImage(_pickedImageBytes!);
      }
    } else {
      if (_pickedImageFile != null) {
        imageProvider = FileImage(_pickedImageFile!);
      }
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          foregroundImage: imageProvider,
        ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text('Add Image'),
        ),
      ],
    );
  }
}
