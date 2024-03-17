import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMemberDialog extends StatefulWidget {
  final String groupId;
  final Function(String userId) onMemberAdded;

  AddMemberDialog(
      {Key? key, required this.groupId, required this.onMemberAdded})
      : super(key: key);

  @override
  _AddMemberDialogState createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  List<String> _currentGroupMembers = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    DocumentSnapshot groupDoc =
        await _firestore.collection('groups').doc(widget.groupId).get();
    if (groupDoc.exists) {
      Map<String, dynamic>? data = groupDoc.data() as Map<String, dynamic>?;
      setState(() {
        _currentGroupMembers = List<String>.from(data?['members'] ?? []);
      });
    }

    setState(() {
      _searchResults = searchResults
          .where((result) => !_currentGroupMembers.contains(result['userId']))
          .toList();
    });
  }

  void _addMember(String userId) async {
    try {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'members': FieldValue.arrayUnion([userId])
      });
      widget.onMemberAdded(userId);
      setState(() {
        _searchResults.removeWhere((result) => result['userId'] == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Member added successfully"),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add member: $error"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Member", style: TextStyle(color: Colors.black)),
      backgroundColor: Color(0xFFFFD4D4),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Search User",
                  suffixIcon: Icon(Icons.search, color: Colors.black),
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: TextStyle(color: Colors.black),
                onChanged: _searchPeople,
              ),
              SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  String username = _searchResults[index]['username']!;
                  String userId = _searchResults[index]['userId']!;
                  return ListTile(
                    title:
                        Text(username, style: TextStyle(color: Colors.black)),
                    trailing: IconButton(
                      icon: Icon(Icons.add, color: Colors.black),
                      onPressed: () => _addMember(userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text("Close", style: TextStyle(color: Colors.black)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
