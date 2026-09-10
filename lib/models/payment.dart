class Payment {
  final int? id;
  final int bookingId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String notes;
  final String? customerName;
  final String? roomNumber;

  const Payment({
    this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.notes,
    this.customerName,
    this.roomNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      bookingId: (map['bookingId'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(
        (map['paymentDate'] ?? DateTime.now().toIso8601String()).toString(),
      ),
      paymentMethod: (map['paymentMethod'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      customerName: map['customerName'] as String?,
      roomNumber: map['roomNumber'] as String?,
    );
  }

  Payment copyWith({
    int? id,
    int? bookingId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    String? customerName,
    String? roomNumber,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      roomNumber: roomNumber ?? this.roomNumber,
    );
  }
}
