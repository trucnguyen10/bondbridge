import 'package:bondbridge/create_group.dart';
import 'package:bondbridge/group_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Stream<QuerySnapshot> _groupsStream() {
    String userId = _auth.currentUser?.uid ?? '';

    var query =
        _firestore.collection('groups').where('members', arrayContains: userId);

    if (_searchText.isNotEmpty) {
      String upperBound = _searchText.substring(0, _searchText.length - 1) +
          String.fromCharCode(
              _searchText.codeUnitAt(_searchText.length - 1) + 1);

      query = query
          .where('name', isGreaterThanOrEqualTo: _searchText)
          .where('name', isLessThan: upperBound);
    }

    return query.snapshots();
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateGroupScreen()),
    );
  }

  void _navigateToGroupDetails(String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GroupDetailsPage(groupId: groupId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset('assets/logo.png', height: 100),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            iconSize: 50,
            onPressed: _navigateToCreateGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[200],
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _groupsStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> group =
                        document.data() as Map<String, dynamic>? ?? {};
                    String groupName = group['name'] as String? ?? 'No Name';
                    String groupPhotoUrl =
                        group['photoUrl'] as String? ?? 'default_image_url';

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(groupName,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(groupPhotoUrl)),
                        onTap: () => _navigateToGroupDetails(document.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
