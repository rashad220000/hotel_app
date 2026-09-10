class Room {
  final int? id;
  final String roomNumber;
  final String roomType;
  final double price;
  final String status;
  final String description;

  const Room({
    this.id,
    required this.roomNumber,
    required this.roomType,
    required this.price,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'price': price,
      'status': status,
      'description': description,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      roomNumber: (map['roomNumber'] ?? '').toString(),
      roomType: (map['roomType'] ?? '').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
    );
  }

  Room copyWith({
    int? id,
    String? roomNumber,
    String? roomType,
    double? price,
    String? status,
    String? description,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      price: price ?? this.price,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}
