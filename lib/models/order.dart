class Order {
  final String id;
  final String usersId;
  final String paymentMethod;
  final String status;
  final double totalPrice;
  final DateTime orderDate;
  final String? catatan;
  final DateTime created;
  final DateTime updated;

  Order({
    required this.id,
    required this.usersId,
    required this.paymentMethod,
    required this.status,
    required this.totalPrice,
    required this.orderDate,
    this.catatan,
    required this.created,
    required this.updated,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      usersId: json['users_id'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? 'pending',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      orderDate: DateTime.parse(json['order_date'] ?? DateTime.now().toIso8601String()),
      catatan: json['catatan'],
      created: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updated: DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'users_id': usersId,
      'payment_method': paymentMethod,
      'status': status,
      'total_price': totalPrice,
      'order_date': orderDate.toIso8601String().split('T')[0], // Only date part
      'catatan': catatan,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'users_id': usersId,
      'payment_method': paymentMethod,
      'status': status,
      'total_price': totalPrice,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'catatan': catatan,
    };
  }

  Order copyWith({
    String? id,
    String? usersId,
    String? paymentMethod,
    String? status,
    double? totalPrice,
    DateTime? orderDate,
    String? catatan,
    DateTime? created,
    DateTime? updated,
  }) {
    return Order(
      id: id ?? this.id,
      usersId: usersId ?? this.usersId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      orderDate: orderDate ?? this.orderDate,
      catatan: catatan ?? this.catatan,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, usersId: $usersId, paymentMethod: $paymentMethod, status: $status, totalPrice: $totalPrice, orderDate: $orderDate, catatan: $catatan)';
  }
}
