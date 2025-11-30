class User {
  final String id;
  final String email;
  final String name;
  
  User({
    required this.id,
    required this.email,
    required this.name,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['full_name'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}
