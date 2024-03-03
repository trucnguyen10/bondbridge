class UserModel {
  final String name;
  final String username;
  final String imageUrl;

  UserModel(
      {required this.name, required this.username, required this.imageUrl});

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      imageUrl: data['image_url'] ?? '',
    );
  }
}
