import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bondbridge/group_edit_page.dart'; // Ensure this file exists
import 'package:bondbridge/add_member.dart'; // Ensure this file exists
import 'package:bondbridge/remove_member.dart'; // Ensure this file exists
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  GroupDetailsPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isMenuOpen = false;
  Map<String, String> _usernameToIdMap = {};
  String _lastSearchQuery = '';
  List<Map<String, String>> _searchResults = []; // Changed to list of maps
  List<String> _currentGroupMembers = [];
  TextEditingController _searchController = TextEditingController();

  String promptOfTheDay = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchPromptOfTheDay();
  }

  Future<void> _fetchPromptOfTheDay() async {
    var promptDoc = await FirebaseFirestore.instance
        .collection('daily_prompt')
        .doc('latest')
        .get();

    if (promptDoc.exists) {
      var promptData = promptDoc.data();
      var content = promptData?['content'];
      setState(() {
        promptOfTheDay = content;
      });
    } else {
      setState(() {
        promptOfTheDay = 'No prompt for today';
      });
    }
  }

  Future<void> _uploadPhoto() async {
    // Use image picker to select the photo
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Upload the file to Firebase Storage
      String fileName =
          'group_photos/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(File(pickedFile.path));

      // Get the URL of the uploaded file
      String photoUrl = await storageRef.getDownloadURL();

      // Store the URL in Firestore under the group's document
      await _firestore.collection('groups').doc(widget.groupId).update({
        'photoUrls': FieldValue.arrayUnion([photoUrl])
      });
    }
  }

  Widget _buildPhotosGrid() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('groups').doc(widget.groupId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasData && snapshot.data!.data() != null) {
          var groupData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> photoUrls = groupData['photoUrls'] ?? [];

          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8, // Spacing between photos
              mainAxisSpacing: 8,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Color(0xFFAACB73), width: 5), // Border color
                  borderRadius:
                      BorderRadius.circular(12), // Circular border radius
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12), // Clip to circular shape
                  child: Image.network(photoUrls[index], fit: BoxFit.cover),
                ),
              );
            },
          );
        }

        return Text('No photos available');
      },
    );
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(widget.groupId).get();
      if (groupDoc.exists) {
        Map<String, dynamic>? data = groupDoc.data() as Map<String, dynamic>?;
        setState(() {
          _currentGroupMembers = List<String>.from(data?['members'] ?? []);
        });
      } else {
        print("Group not found");
      }
    } catch (e) {
      print("Error fetching group: $e");
    }
  }

  void _updateSearchResults(String userId) {
    setState(() {
      _currentGroupMembers.add(userId);
      _searchResults.removeWhere((result) => result['userId'] == userId);
    });
  }

  Future<void> _searchPeople(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    String lowerBound = query.toLowerCase();
    String upperBound = lowerBound.substring(0, lowerBound.length - 1) +
        String.fromCharCode(lowerBound.codeUnitAt(lowerBound.length - 1) + 1);

    QuerySnapshot snapshot = await _firestore
        .collection('userstorage')
        .where('username', isGreaterThanOrEqualTo: lowerBound)
        .where('username', isLessThan: upperBound)
        .get();

    var searchResults = snapshot.docs.map((doc) {
      return {'username': doc['username'].toString(), 'userId': doc.id};
    }).toList();

    print(searchResults);

    print(_currentGroupMembers);

    setState(() {
      _searchResults = searchResults
          .where((result) => !_currentGroupMembers.contains(result['userId']))
          .toList();
    });
  }

  void _addPersonToGroup(String userId) async {
    if (!_currentGroupMembers.contains(userId)) {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayUnion([userId])
      }).then((_) {
        setState(() {
          _currentGroupMembers.add(userId);
          _searchResults.removeWhere((result) => result['userId'] == userId);
          print(_searchResults);
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User added to the group")));
      }).catchError((error) {
        print("Error updating group members: $error");
      });
    }
  }

  void _showAddPeopleModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddMemberDialog(
          groupId: widget.groupId,
          onMemberAdded: _updateSearchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFE8), // Change background color
      appBar: AppBar(
        title: Center(
          child: Image.asset('assets/logo.png', height: 100),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
            onSelected: _selectMenuOption,
            onCanceled: () {
              setState(() {
                _isMenuOpen = false;
              });
            },
            onOpened: () {
              setState(() {
                _isMenuOpen = true;
              });
            },
            itemBuilder: (BuildContext context) {
              return {'Add People', 'Remove People', 'Edit Group'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Today's Prompt:",
                      style: GoogleFonts.anton(
                        fontSize: 30,
                        color: Color.fromARGB(150, 240, 21,
                            21), // Using hexadecimal code for FFD4D4
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      promptOfTheDay,
                      style:
                          GoogleFonts.lato(fontSize: 17, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_a_photo),
              onPressed: _uploadPhoto,
            ),
            _buildPhotosGrid(),
            // Additional content here
          ],
        ),
      ),
    );
  }

  void _selectMenuOption(String choice) {
    setState(() {
      _isMenuOpen = false;
    });

    if (choice == 'Edit Group') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupEditPage(groupId: widget.groupId),
        ),
      );
    } else if (choice == 'Add People') {
      _showAddPeopleModal();
    } else if (choice == 'Remove People') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RemoveMember(groupId: widget.groupId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }
}
