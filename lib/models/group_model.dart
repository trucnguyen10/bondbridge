import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final List<String> members;
  final String photoUrl;

  Group(
      {required this.id,
      required this.name,
      required this.members,
      required this.photoUrl});

  // Creates a Group from a Firestore document.
  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  // Converts Group instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'photoUrl': photoUrl,
    };
  }
}
