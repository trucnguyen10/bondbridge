import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class UserImagePicker extends StatefulWidget {
  final void Function(dynamic pickedImage) onPickImage;

  const UserImagePicker({Key? key, required this.onPickImage})
      : super(key: key);

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  Uint8List? _webImage;
  File? _mobileImage;

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
            _webImage = reader.result as Uint8List;
          });
          widget.onPickImage(_webImage);
        });
      });
    } else {
      // Mobile-specific logic
      // Implement mobile image picking logic using image_picker or similar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_webImage != null || _mobileImage != null)
          Image.memory(_webImage ?? _mobileImage!.readAsBytesSync()),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Pick Image'),
        ),
      ],
    );
  }
}
