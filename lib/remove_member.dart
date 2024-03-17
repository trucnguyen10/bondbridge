import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemoveMember extends StatefulWidget {
  final String groupId;

  RemoveMember({Key? key, required this.groupId}) : super(key: key);

  @override
  _RemoveMemberState createState() => _RemoveMemberState();
}

class _RemoveMemberState extends State<RemoveMember> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _nameController = TextEditingController();
  String _groupImageUrl = '';
  List<String> _groupMemberIds = []; // Store member IDs

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
        _nameController.text = data?['name'] ?? '';
        _groupImageUrl = data?['photoUrl'] ?? '';
        _groupMemberIds =
            List<String>.from(data?['members'] ?? []); // Storing member IDs
        setState(() {});
      } else {
        print("Group not found");
      }
    } catch (e) {
      print("Error fetching group: $e");
    }
  }

  void _removeMember(String memberId) {
    setState(() {
      _groupMemberIds.remove(memberId);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset('assets/logo.png', height: 100),
        ),
      ),
      backgroundColor: Color(0xFFFFF7F1),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // TextField(
            //   controller: _nameController,
            //   decoration: InputDecoration(
            //     labelText: 'Change Group Name',
            //     labelStyle: TextStyle(color: Colors.black), // Label color
            //     enabledBorder: OutlineInputBorder(
            //       borderSide: BorderSide(color: Colors.black), // Border color
            //     ),
            //     focusedBorder: OutlineInputBorder(
            //       borderSide: BorderSide(color: Colors.black),
            //     ),
            //   ),
            //   style: TextStyle(color: Colors.black), // Text field input color
            // ),
            SizedBox(height: 10),
            Text(
              'Group Members:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 30),
            ),
            ..._groupMemberIds.map((memberId) =>
                MemberTile(memberId: memberId, onRemove: _removeMember)),
            SizedBox(height: 10),
            Center(
              // Add this widget to center the button
              child: ElevatedButton(
                onPressed: _updateGroup,
                child: Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.black), // Text color
                ),
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFFFFD4D4), // Background color
                  elevation: 0, // Remove shadow
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateGroup() async {
    Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'members': _groupMemberIds,
    };

    try {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .update(updatedData);
      Navigator.pop(context);
    } catch (error) {
      print("Error updating group: $error");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class MemberTile extends StatelessWidget {
  final String memberId;
  final Function(String) onRemove;

  MemberTile({required this.memberId, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('userstorage')
          .doc(memberId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null &&
            snapshot.data!.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;
          String username = userData['username'] ?? 'Unknown';
          return ListTile(
            title: Text(username),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle_outline),
              onPressed: () => onRemove(memberId),
            ),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
