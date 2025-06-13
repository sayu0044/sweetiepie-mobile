class Like {
  final String id;
  final String productsId;
  final String usersId;
  final DateTime created;
  final DateTime updated;

  Like({
    required this.id,
    required this.productsId,
    required this.usersId,
    required this.created,
    required this.updated,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? '',
      productsId: json['products_id'] ?? '',
      usersId: json['users_id'] ?? '',
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      updated: DateTime.tryParse(json['updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products_id': productsId,
      'users_id': usersId,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'products_id': productsId,
      'users_id': usersId,
    };
  }

  Like copyWith({
    String? id,
    String? productsId,
    String? usersId,
    DateTime? created,
    DateTime? updated,
  }) {
    return Like(
      id: id ?? this.id,
      productsId: productsId ?? this.productsId,
      usersId: usersId ?? this.usersId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
