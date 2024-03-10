import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupEditPage extends StatefulWidget {
  final String groupId;

  GroupEditPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupEditPageState createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _nameController = TextEditingController();
  String _groupImageUrl = ''; // Variable for group image URL
  List<String> _groupMembers = []; // List of group members

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<String> _fetchUsername(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('userstorage').doc(userId).get();
    if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['username'] ?? ''; // Assuming 'username' field exists
    }
    return ''; // Return empty string if user not found or data is not in expected format
  }

  Future<void> _fetchGroupData() async {
    try {
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(widget.groupId).get();
      if (groupDoc.exists) {
        Map<String, dynamic>? data = groupDoc.data() as Map<String, dynamic>?;
        _nameController.text = data?['name'] ?? '';
        _groupImageUrl = data?['photoUrl'] ?? '';

        // Fetch usernames for each member ID
        List<String> memberUsernames = [];
        for (String memberId in List<String>.from(data?['members'] ?? [])) {
          String username = await _fetchUsername(memberId);
          if (username.isNotEmpty) {
            memberUsernames.add(username);
          }
        }

        setState(() {
          _groupMembers = memberUsernames; // Storing usernames for UI display
        });
      } else {
        print("Group not found");
      }
    } catch (e) {
      print("Error fetching group: $e");
    }
  }

  void _removeMember(String memberId) {
    // Logic to remove the member from the group
    setState(() {
      _groupMembers.remove(memberId);
    });
    // Additionally, update the members in Firestore if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Group'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
            SizedBox(height: 10),
            // Display group image
            _groupImageUrl.isNotEmpty
                ? Center(
                    // Center the image
                    child: Image.network(_groupImageUrl,
                        fit: BoxFit.cover, height: 200),
                  )
                : Placeholder(fallbackHeight: 200),
            SizedBox(height: 10),
            Text('Group Members:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._groupMembers
                .map((memberId) => ListTile(
                      title: Text(memberId),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeMember(memberId),
                      ),
                    ))
                .toList(),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateGroup,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateGroup() async {
    // Make sure _groupMembers contains user IDs here
    List<String> memberIds = await _getUserIdsFromUsernames(_groupMembers);

    Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'members': memberIds, // Use member IDs for the update
      // 'photoUrl': _groupImageUrl, // Uncomment if you're updating the group image
    };

    try {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .update(updatedData);
      print("Group successfully updated");
      Navigator.pop(context); // Go back after updating the group
    } catch (error) {
      print("Error updating group: $error");
    }
  }

  Future<List<String>> _getUserIdsFromUsernames(List<String> usernames) async {
    List<String> userIds = [];
    for (String username in usernames) {
      var userQuery = await _firestore
          .collection('userstorage')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        userIds.add(userQuery.docs.first.id);
      }
    }
    return userIds;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
