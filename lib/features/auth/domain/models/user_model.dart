class UserModel {
  final String id;
  final String name;
  final String email;
  final String passwordHash;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    passwordHash: map['passwordHash'],
  );
}