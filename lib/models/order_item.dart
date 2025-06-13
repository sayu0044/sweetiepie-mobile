class OrderItem {
  final String id;
  final String orderId;
  final String productsId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime created;
  final DateTime updated;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productsId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.created,
    required this.updated,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      productsId: json['products_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      created: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updated: DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'products_id': productsId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'order_id': orderId,
      'products_id': productsId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productsId,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    DateTime? created,
    DateTime? updated,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productsId: productsId ?? this.productsId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, orderId: $orderId, productsId: $productsId, quantity: $quantity, unitPrice: $unitPrice, subtotal: $subtotal)';
  }
}
