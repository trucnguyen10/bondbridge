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

  Future<Map<String, dynamic>?> _fetchGroupData() async {
    try {
      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(widget.groupId).get();
      if (groupDoc.exists) {
        return groupDoc.data() as Map<String, dynamic>?;
      } else {
        print("Group not found");
        return null; // Or handle this case appropriately
      }
    } catch (e) {
      print("Error fetching group: $e");
      return null; // Or handle the error appropriately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchGroupData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading...");
            }

            if (snapshot.hasError) {
              return Text("Error");
            }

            if (snapshot.hasData && snapshot.data != null) {
              return Text(snapshot.data!['name']);
            }

            return Text("Group Details");
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchGroupData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading group details"));
          }

          if (snapshot.hasData && snapshot.data != null) {
            Map<String, dynamic> groupData = snapshot.data!;
            return Center(
                child: Text("Group Details for ${groupData['name']}"));
            // You can add more UI elements here based on groupData
          }

          return Center(child: Text("Group not found"));
        },
      ),
    );
  }
}
