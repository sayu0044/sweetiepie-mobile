class UserSettings {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final String? theme;
  final bool notifications;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime created;
  final DateTime updated;

  UserSettings({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    this.theme,
    this.notifications = true,
    this.dateOfBirth,
    this.gender,
    required this.created,
    required this.updated,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      avatar: json['avatar'],
      theme: json['theme'],
      notifications: json['notifications'] ?? true,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'avatar': avatar,
        'theme': theme,
        'notifications': notifications,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'phone': phone,
        'address': address,
        'theme': theme,
        'notifications': notifications,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
      };

  UserSettings copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatar,
    String? theme,
    bool? notifications,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? created,
    DateTime? updated,
  }) {
    return UserSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
