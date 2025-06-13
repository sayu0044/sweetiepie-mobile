class Cart {
  final String id;
  final String productsId;
  final int jumlahBarang;
  final String usersId;
  final DateTime created;
  final DateTime updated;
  final bool isSelected;

  Cart({
    required this.id,
    required this.productsId,
    required this.jumlahBarang,
    required this.usersId,
    required this.created,
    required this.updated,
    this.isSelected = true,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? '',
      productsId: json['products_id'] ?? '',
      jumlahBarang: json['jumlah_barang'] ?? 0,
      usersId: json['users_id'] ?? '',
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      updated: DateTime.tryParse(json['updated'] ?? '') ?? DateTime.now(),
      isSelected: json['is_selected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products_id': productsId,
      'jumlah_barang': jumlahBarang,
      'users_id': usersId,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'is_selected': isSelected,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'products_id': productsId,
      'jumlah_barang': jumlahBarang,
      'users_id': usersId,
      'is_selected': isSelected,
    };
  }

  Cart copyWith({
    String? id,
    String? productsId,
    int? jumlahBarang,
    String? usersId,
    DateTime? created,
    DateTime? updated,
    bool? isSelected,
  }) {
    return Cart(
      id: id ?? this.id,
      productsId: productsId ?? this.productsId,
      jumlahBarang: jumlahBarang ?? this.jumlahBarang,
      usersId: usersId ?? this.usersId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
