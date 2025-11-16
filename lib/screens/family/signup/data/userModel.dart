class UserModel {
  String? id;
  String email;
  String name;
  String role;

  UserModel(
      {this.id, required this.email, required this.name, this.role = "family"});

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
        email: data['email'],
        name: data['name'],
        id: data['id'],
        role: data['role']);
  }
}
