class OrderItem {
  final String id;
  final String orderId;
  final String productsId;
  final int jumlah;
  final double harga;
  final DateTime created;
  final DateTime updated;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productsId,
    required this.jumlah,
    required this.harga,
    required this.created,
    required this.updated,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      productsId: json['products_id'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      harga: (json['harga'] ?? 0.0).toDouble(),
      created:
          DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updated:
          DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'products_id': productsId,
      'jumlah': jumlah,
      'harga': harga,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productsId,
    int? jumlah,
    double? harga,
    DateTime? created,
    DateTime? updated,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productsId: productsId ?? this.productsId,
      jumlah: jumlah ?? this.jumlah,
      harga: harga ?? this.harga,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
