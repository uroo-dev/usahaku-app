enum TransactionType { income, expense }
enum PaymentMethod { cash, qris, transfer }

class TransactionModel {
  final int? id;
  final TransactionType type;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final int? customerId;
  final int? supplierId;
  final DateTime? createdAt;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.category = 'Lainnya',
    required this.date,
    this.paymentMethod = PaymentMethod.cash,
    this.customerId,
    this.supplierId,
    this.createdAt,
  });

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    PaymentMethod? paymentMethod,
    int? customerId,
    int? supplierId,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedAmount {
    final sign = type == TransactionType.income ? '+' : '-';
    return '$sign Rp ${amount.toStringAsFixed(0).replaceAll(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), r'$1.')}';
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get formattedTime {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get paymentLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.transfer:
        return 'Transfer';
    }
  }
}