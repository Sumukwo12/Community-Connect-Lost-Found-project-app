class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImage;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImage,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:           (json['id'] is int) ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName:     json['full_name']     as String? ?? '',
      email:        json['email']         as String? ?? '',
      phone:        json['phone']         as String? ?? '',
      profileImage: json['profile_image'] as String?,
      createdAt:    json['created_at']    as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'full_name':     fullName,
    'email':         email,
    'phone':         phone,
    'profile_image': profileImage,
    'created_at':    createdAt,
  };

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? profileImage,
    String? createdAt,
  }) {
    return UserModel(
      id:           id           ?? this.id,
      fullName:     fullName     ?? this.fullName,
      email:        email        ?? this.email,
      phone:        phone        ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt:    createdAt    ?? this.createdAt,
    );
  }
}
