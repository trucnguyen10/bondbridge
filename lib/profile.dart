import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _userModel;

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
        setState(() {
          _userModel =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF7F1),
      appBar: AppBar(
        title:
            Image.asset('assets/logo.png', height: 100), // Logo in the middle
        actions: [
          IconButton(
            icon: Icon(
              Icons.home,
              size: 40.0, // Adjust the size as needed
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
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
                  Text(
                    'Name: ${_userModel!.name}',
                    style: GoogleFonts.anton(
                      fontSize: 30,
                      color: Color(0xffe78895),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Username: ${_userModel!.username}',
                      style: GoogleFonts.anton(
                          fontSize: 20, color: Color(0xffBED1CF))),
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_userModel!.imageUrl),
                  ),
                  // Other fields or buttons if needed
                ],
              ),
      ),
    );
  }
}
