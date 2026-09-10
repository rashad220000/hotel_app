class Booking {
  final int? id;
  final int customerId;
  final int roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfNights;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final String? roomNumber;

  const Booking({
    this.id,
    required this.customerId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfNights,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.roomNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'roomId': roomId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'numberOfNights': numberOfNights,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      customerId: (map['customerId'] as num?)?.toInt() ?? 0,
      roomId: (map['roomId'] as num?)?.toInt() ?? 0,
      checkIn: DateTime.parse(
        (map['checkIn'] ?? DateTime.now().toIso8601String()).toString(),
      ),
      checkOut: DateTime.parse(
        (map['checkOut'] ?? DateTime.now().toIso8601String()).toString(),
      ),
      numberOfNights: (map['numberOfNights'] as num?)?.toInt() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] ?? '').toString(),
      createdAt: DateTime.parse(
        (map['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      ),
      customerName: map['customerName'] as String?,
      roomNumber: map['roomNumber'] as String?,
    );
  }

  Booking copyWith({
    int? id,
    int? customerId,
    int? roomId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? numberOfNights,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    String? customerName,
    String? roomNumber,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      roomId: roomId ?? this.roomId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      roomNumber: roomNumber ?? this.roomNumber,
    );
  }
}
