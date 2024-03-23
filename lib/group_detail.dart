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

  Future<void> _uploadPhoto() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        String fileName =
            'group_photos/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        await storageRef.putFile(File(pickedFile.path));
        String photoUrl = await storageRef.getDownloadURL();

        // Create a new document in 'photos' collection
        DocumentReference photoDocRef =
            await _firestore.collection('photos').add({
          'url': photoUrl,
          'userId': userId,
          'groupId': widget
              .groupId, // If you want to keep track of which group the photo belongs to
          'likes': 0, // Initialize likes
          'comments': [] // Initialize comments
        });

        // Update the 'groups' document as well
        await _firestore.collection('groups').doc(widget.groupId).update({
          'photos': FieldValue.arrayUnion([
            {'url': photoUrl, 'userId': userId, 'photoId': photoDocRef.id}
          ])
        });

        print('Photo uploaded successfully: $photoUrl');
      } else {
        print('No photo selected');
      }
    } catch (e) {
      print('Error uploading photo: $e');
    }
  }

  Widget _buildPhotosGrid() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('groups').doc(widget.groupId).snapshots(),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (groupSnapshot.hasData && groupSnapshot.data!.data() != null) {
          var groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> photos = groupData['photos'] ?? [];

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                var photoInfo = photos[index];
                String photoId = photoInfo['photoId'];
                String userId = photoInfo['userId'];

                return StreamBuilder<DocumentSnapshot>(
                  stream:
                      _firestore.collection('photos').doc(photoId).snapshots(),
                  builder: (context, photoSnapshot) {
                    if (photoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    var photoData =
                        photoSnapshot.data?.data() as Map<String, dynamic>? ??
                            {};
                    int likeCount = photoData['likes'] ?? 0;
                    bool isLiked = likeCount > 0;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('userstorage')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String userProfileUrl = '';
                        if (userSnapshot.connectionState ==
                                ConnectionState.done &&
                            userSnapshot.data != null) {
                          userProfileUrl =
                              userSnapshot.data!['image_url'] ?? '';
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Color(0xFFAACB73), width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.network(
                                  photoInfo['url'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: userProfileUrl.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(userProfileUrl),
                                          radius: 12,
                                        )
                                      : Container(width: 24, height: 24),
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                        onPressed: () => _likePhoto(photoId),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: 0), // Reduced left margin
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$likeCount',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: Icon(Icons.comment),
                                    onPressed: () => _showComments(
                                        photoId, photoData['comments'] ?? []),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        }

        return Text('No photos available');
      },
    );
  }

  Future<void> _likePhoto(String photoId) async {
    try {
      DocumentReference photoRef = _firestore.collection('photos').doc(photoId);

      _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(photoRef);

        if (!snapshot.exists) {
          throw Exception("Photo does not exist!");
        }

        // Cast the snapshot data to Map<String, dynamic>
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        int currentLikes = data['likes'] ?? 0;
        transaction.update(photoRef, {'likes': currentLikes + 1});
      }).then((result) {
        print("Photo liked successfully.");
      }).catchError((error) {
        print("Error liking photo: $error");
      });
    } catch (e) {
      print("Error processing like: $e");
    }
  }

  void _showComments(String photoId, List<dynamic> comments) {
    TextEditingController _commentController = TextEditingController();

    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Image.asset('assets/logo.png', height: 100),
            backgroundColor: Color(0xFFFFF7E8),
            elevation: 0,
            centerTitle: true, // Add this line
          ),
          body: Padding(
            // Adding Padding here
            padding:
                EdgeInsets.symmetric(horizontal: 12), // Set horizontal padding
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        ...comments.map((comment) {
                          // Assuming each comment is a Map with 'text' and 'userId'
                          String commentText = comment['text'];
                          String userId = comment['userId'];
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('userstorage')
                                .doc(userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data != null) {
                                Map<String, dynamic> userData = snapshot.data!
                                    .data() as Map<String, dynamic>;
                                String username =
                                    userData['username'] ?? 'Unknown';
                                return ListTile(
                                  title: Text(username,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(commentText),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration:
                              InputDecoration(hintText: "Add a comment"),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          String userId =
                              FirebaseAuth.instance.currentUser?.uid ??
                                  'unknown';
                          Map<String, String> newComment = {
                            'userId': userId,
                            'text': _commentController.text
                          };

                          await _firestore
                              .collection('photos')
                              .doc(photoId)
                              .update({
                            'comments': FieldValue.arrayUnion([newComment])
                          });

                          _commentController.clear();
                          Navigator.of(context).pop();
                        },
                        child: Text("Send comment"),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFFFD4D4), // Background color
                          onPrimary: Colors.black, // Text color
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Color(0xFFFFF7E8),
        );
      },
    ));
  }

  Future<List<Widget>> _fetchCommentData(List<dynamic> comments) async {
    List<Widget> commentWidgets = [];
    for (var comment in comments) {
      String userId = comment['userId']; // Assuming comment has userId
      String text = comment['text']; // Assuming comment has text

      DocumentSnapshot userSnapshot =
          await _firestore.collection('userstorage').doc(userId).get();

      // Cast the data to a Map<String, dynamic>
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic> ?? {};
      String username = userData['username'] ?? 'Unknown';

      commentWidgets.add(
        RichText(
          text: TextSpan(
            text: '$username: ',
            style: TextStyle(fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                  text: text, style: TextStyle(fontWeight: FontWeight.normal))
            ],
          ),
        ),
      );
    }
    return commentWidgets;
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
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Today's Prompt",
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
                          GoogleFonts.lato(fontSize: 16, color: Colors.black),
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
