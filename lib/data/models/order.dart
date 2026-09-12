enum OrderStatus { pending, confirmed, preparing, delivered, cancelled }

OrderStatus orderStatusFromString(String value) =>
    OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'قيد الانتظار';
    case OrderStatus.confirmed:
      return 'تم التأكيد';
    case OrderStatus.preparing:
      return 'جاري التجهيز';
    case OrderStatus.delivered:
      return 'تم التوصيل';
    case OrderStatus.cancelled:
      return 'ملغي';
  }
}

class DiscountValidation {
  const DiscountValidation({
    required this.valid,
    this.code,
    this.customerDiscountPercent = 0,
  });

  final bool valid;
  final String? code;
  final double customerDiscountPercent;

  double amount(double subtotal) =>
      valid ? subtotal * customerDiscountPercent / 100 : 0;
}

class OrderDraft {
  const OrderDraft({
    required this.customerName,
    required this.phone,
    required this.city,
    required this.address,
    required this.notes,
    required this.discountCode,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.discountPercent = 0,
  });

  final String customerName;
  final String phone;
  final String city;
  final String address;
  final String notes;
  final String? discountCode;
  final double subtotal;
  final double discountAmount;
  final double total;
  final double discountPercent;
}

class OrderReceipt {
  const OrderReceipt({
    required this.orderNumber,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final String orderNumber;
  final double subtotal;
  final double discount;
  final double total;

  factory OrderReceipt.fromMap(Map<String, dynamic> data) {
    double number(String key) => (data[key] as num?)?.toDouble() ?? 0;

    return OrderReceipt(
      orderNumber: data['order_number'] as String? ?? '',
      subtotal: number('subtotal'),
      discount: number('discount'),
      total: number('total'),
    );
  }
}
