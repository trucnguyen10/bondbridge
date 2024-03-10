import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  GroupDetailsPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isMenuOpen = false;
  String _lastSearchQuery = ''; // Add this to store the last search query
  List<String> _searchResults = [];
  List<String> _currentGroupMembers = [];
  Set<String> _addedInSession = Set();

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

  Future<List<String>> _searchPeople(String query) async {
    QuerySnapshot snapshot = await _firestore
        .collection('userstorage')
        .where('username', isGreaterThanOrEqualTo: query)
        .get();

    return snapshot.docs
        .map((doc) => doc['username'].toString())
        .where((username) => !_currentGroupMembers.contains(username))
        .toList();
  }

  void _addPersonToGroup(String personName) async {
    if (!_currentGroupMembers.contains(personName)) {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayUnion([personName])
      }).then((_) {
        setState(() {
          // Add to current members
          _currentGroupMembers.add(personName);
          // Remove the person from the search results list
          _searchResults.remove(personName);
        });
        print("Person successfully added to the group");
      }).catchError((error) {
        print("Error updating group members: $error");
      });
    }
    setState(() {});
  }

  void _showAddPeopleModal() {
    // Ensure group data is loaded before allowing searches
    if (_currentGroupMembers.isEmpty) {
      return; // Optionally, show a loading indicator or a message
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search People',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      _lastSearchQuery = value; // Store the last search query
                      if (value.isNotEmpty) {
                        List<String> results = await _searchPeople(value);
                        setState(() {
                          _searchResults = results;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      String personName = _searchResults[index];
                      return ListTile(
                        title: Text(personName),
                        trailing: IconButton(
                          icon: Icon(_currentGroupMembers.contains(personName)
                              ? Icons.check
                              : Icons.add),
                          onPressed: _currentGroupMembers.contains(personName)
                              ? null
                              : () => _addPersonToGroup(personName),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Group Details"),
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

    if (choice == 'Add People') {
      _showAddPeopleModal();
    } else {
      // Handle other choices here
    }
  }
}
