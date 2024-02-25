import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'widget/user_image_picker.dart'; // Ensure this path is correct

final FirebaseAuth _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredName = ''; // New field for name
  var _enteredUsername = ''; // New field for username
  var _isLogin = true;
  File? _selectedImage;

  void _submit() async {
    final isValid = _form.currentState!.validate();
    FocusScope.of(context).unfocus(); // Close the keyboard

    // if (!isValid || (!_isLogin && _selectedImage == null)) {
    //   if (!_isLogin && _selectedImage == null) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Please pick an image.')),
    //     );
    //   }
    //   return;
    // }

    _form.currentState!.save();
    print(_form.currentState!.validate());

    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        // Handle successful login, e.g., navigate to another screen
      } else {
        print('creating user');
        print(_enteredEmail);
        print(_enteredPassword);
        userCredential = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        // Upload image to Firebase Storage
        // final storageRef = FirebaseStorage.instance
        //     .ref()
        //     .child('user_images')
        //     .child('${userCredential.user!.uid}.jpg');
        // await storageRef.putFile(_selectedImage!);
        // final imageUrl = await storageRef.getDownloadURL();

        // Store username and image URL in Firestore

        try {
          print('uploading to firestore');
          print(userCredential.user!.uid);
          print(_enteredUsername);
          print(_enteredEmail);
          print(_enteredName);
          await FirebaseFirestore.instance
              .collection('userstorage')
              .doc(userCredential.user!.uid)
              .set({
            'username': _enteredUsername,
            'email': _enteredEmail,
            'name': _enteredName,
            // 'image_url': imageUrl,
          });
          print('uploaded to firestore');
        } catch (error) {
          print('Error: $error');
        }

        // Store additional user information (e.g., name, username) in Firebase
        // This can be in FirebaseAuth profile or in a Firestore document

        // Clear form data and reset state
        _form.currentState!.reset();
        setState(() {
          _enteredEmail = '';
          _enteredPassword = '';
          // _selectedImage = null;
          _isLogin = true; // Switch back to login mode after sign up
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF7F1),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset(
                    'assets/logo.png'), // Ensure you have this image in your assets
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // if (!_isLogin)
                        //   UserImagePicker(
                        //     onPickImage: (pickedImage) {
                        //       _selectedImage = pickedImage;
                        //     },
                        //   ),
                        if (!_isLogin)
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredName = value!;
                            },
                          ),
                        if (!_isLogin)
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Username'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredUsername = value!;
                            },
                          ),
                        TextFormField(
                          key: const ValueKey('email'),
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredEmail = value!;
                          },
                        ),
                        TextFormField(
                          key: const ValueKey('password'),
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 7) {
                              return 'Password must be at least 7 characters long.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredPassword = value!;
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Don\'t have an account? Sign Up'
                                : 'Already have an account? Sign In',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
