import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bondbridge/group_edit_page.dart'; // Ensure this file exists
import 'package:bondbridge/add_member.dart'; // Ensure this file exists
import 'package:bondbridge/remove_member.dart'; // Ensure this file exists

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

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
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
      backgroundColor: Color(0xFFFFF7F1),
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
      body: Center(
        child: Text("Group Details"),
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
