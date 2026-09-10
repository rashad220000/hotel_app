class Customer {
  final int? id;
  final String name;
  final String phone;
  final String nationalId;
  final String address;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'nationalId': nationalId,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      nationalId: (map['nationalId'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? nationalId,
    String? address,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
    );
  }
}
