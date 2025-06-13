class Order {
  final String id;
  final String usersId;
  final String? paymentMethodId;
  final String status;
  final double totalPrice;
  final DateTime created;
  final DateTime updated;

  Order({
    required this.id,
    required this.usersId,
    this.paymentMethodId,
    required this.status,
    required this.totalPrice,
    required this.created,
    required this.updated,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      usersId: json['users_id'] ?? '',
      paymentMethodId: json['payment_method_id'],
      status: json['status'] ?? 'pending',
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      created:
          DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updated:
          DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'users_id': usersId,
      'payment_method_id': paymentMethodId,
      'status': status,
      'total_price': totalPrice,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? usersId,
    String? paymentMethodId,
    String? status,
    double? totalPrice,
    DateTime? created,
    DateTime? updated,
  }) {
    return Order(
      id: id ?? this.id,
      usersId: usersId ?? this.usersId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
