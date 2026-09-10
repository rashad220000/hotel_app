import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/booking.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/room.dart';
import '../utils/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.dbName);

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roomNumber TEXT NOT NULL UNIQUE,
        roomType TEXT NOT NULL,
        price REAL NOT NULL,
        status TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        nationalId TEXT NOT NULL,
        address TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        checkIn TEXT NOT NULL,
        checkOut TEXT NOT NULL,
        numberOfNights INTEGER NOT NULL,
        totalPrice REAL NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE CASCADE,
        FOREIGN KEY (roomId) REFERENCES rooms(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookingId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        notes TEXT NOT NULL,
        FOREIGN KEY (bookingId) REFERENCES bookings(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> deleteDatabaseFile() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('payments');
    await db.delete('bookings');
    await db.delete('customers');
    await db.delete('rooms');
  }

  // Rooms CRUD
  Future<int> insertRoom(Room room) async {
    final db = await database;
    final res = await db.insert(
      'rooms',
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return res;
  }

  Future<List<Room>> getAllRooms() async {
    final db = await database;
    final maps = await db.query('rooms', orderBy: 'id ASC');
    return maps.map((e) => Room.fromMap(e)).toList();
  }

  Future<List<Room>> getAvailableRooms() async {
    final db = await database;
    final maps = await db.query(
      'rooms',
      where: 'status = ?',
      whereArgs: [AppConstants.roomStatusAvailable],
      orderBy: 'id ASC',
    );
    return maps.map((e) => Room.fromMap(e)).toList();
  }

  Future<int> updateRoom(Room room) async {
    final db = await database;
    return db.update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<int> deleteRoom(int id) async {
    final db = await database;
    return db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateRoomStatus(int roomId, String status) async {
    final db = await database;
    return db.update(
      'rooms',
      {'status': status},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  // Customers CRUD
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'id ASC');
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final q = query.trim();
    if (q.isEmpty) return getAllCustomers();
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$q%', '%$q%'],
      orderBy: 'name ASC',
    );
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Bookings CRUD
  Future<int> insertBooking(Booking booking) async {
    final db = await database;
    return db.insert('bookings', booking.toMap());
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.*, c.name as customerName, r.roomNumber as roomNumber
      FROM bookings b
      LEFT JOIN customers c ON c.id = b.customerId
      LEFT JOIN rooms r ON r.id = b.roomId
      ORDER BY b.createdAt DESC
    ''');
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  Future<List<Booking>> getActiveBookings() async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name as customerName, r.roomNumber as roomNumber
      FROM bookings b
      LEFT JOIN customers c ON c.id = b.customerId
      LEFT JOIN rooms r ON r.id = b.roomId
      WHERE b.status = ?
      ORDER BY b.createdAt DESC
    ''',
      [AppConstants.bookingStatusActive],
    );
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  Future<List<Booking>> getCompletedBookings() async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name as customerName, r.roomNumber as roomNumber
      FROM bookings b
      LEFT JOIN customers c ON c.id = b.customerId
      LEFT JOIN rooms r ON r.id = b.roomId
      WHERE b.status = ?
      ORDER BY b.createdAt DESC
    ''',
      [AppConstants.bookingStatusCompleted],
    );
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  Future<int> updateBookingStatus(int bookingId, String status) async {
    final db = await database;
    return db.update(
      'bookings',
      {'status': status},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await database;
    return db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await database;
    return db.delete('bookings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countActiveBookings() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bookings WHERE status = ?',
      [AppConstants.bookingStatusActive],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Booking?> getBookingById(int bookingId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name as customerName, r.roomNumber as roomNumber
      FROM bookings b
      LEFT JOIN customers c ON c.id = b.customerId
      LEFT JOIN rooms r ON r.id = b.roomId
      WHERE b.id = ?
    ''',
      [bookingId],
    );
    if (maps.isEmpty) return null;
    return Booking.fromMap(maps.first);
  }

  Future<void> createBookingWithRoomUpdate({
    required Booking booking,
    required int roomId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('bookings', booking.toMap());
      await txn.update(
        'rooms',
        {'status': AppConstants.roomStatusBooked},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    });
  }

  Future<void> completeOrCancelBooking({
    required int bookingId,
    required int roomId,
    required String status,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'bookings',
        {'status': status},
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      await txn.update(
        'rooms',
        {'status': AppConstants.roomStatusAvailable},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    });
  }

  // Payments CRUD
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT p.*, c.name as customerName, r.roomNumber as roomNumber
      FROM payments p
      LEFT JOIN bookings b ON b.id = p.bookingId
      LEFT JOIN customers c ON c.id = b.customerId
      LEFT JOIN rooms r ON r.id = b.roomId
      ORDER BY p.paymentDate DESC
    ''');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<double> getTotalPayments() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Payment>> getPaymentsByBookingId(int bookingId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT p.*, c.name as customerName, r.roomNumber as roomNumber
      FROM payments p
      LEFT JOIN bookings b ON b.id = p.bookingId
      LEFT JOIN customers c ON c.id = b.customerId
      LEFT JOIN rooms r ON r.id = b.roomId
      WHERE p.bookingId = ?
      ORDER BY p.paymentDate DESC
    ''',
      [bookingId],
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<double> getBookingTotalPaid(int bookingId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE bookingId = ?',
      [bookingId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getDashboardTotalPayments() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final roomsResult = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as totalRooms,
        SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as availableRooms,
        SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as bookedRooms,
        SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as maintenanceRooms
      FROM rooms
    ''',
      [
        AppConstants.roomStatusAvailable,
        AppConstants.roomStatusBooked,
        AppConstants.roomStatusMaintenance,
      ],
    );

    final bookingsResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as activeBookings FROM bookings WHERE status = ?
    ''',
      [AppConstants.bookingStatusActive],
    );

    final paymentsResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments',
    );

    final roomMap = roomsResult.first;
    final bookingMap = bookingsResult.first;
    final paymentMap = paymentsResult.first;

    return {
      'totalRooms': (roomMap['totalRooms'] as int?) ?? 0,
      'availableRooms': (roomMap['availableRooms'] as int?) ?? 0,
      'bookedRooms': (roomMap['bookedRooms'] as int?) ?? 0,
      'maintenanceRooms': (roomMap['maintenanceRooms'] as int?) ?? 0,
      'activeBookings': (bookingMap['activeBookings'] as int?) ?? 0,
      'totalPayments': (paymentMap['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<bool> roomNumberExists(String roomNumber, {int? excludeId}) async {
    final db = await database;
    final result = await db.query(
      'rooms',
      where: 'roomNumber = ? AND id != ?',
      whereArgs: [roomNumber.trim(), excludeId ?? -1],
    );
    return result.isNotEmpty;
  }

  Future<bool> customerExistsByPhone(String phone, {int? excludeId}) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'phone = ? AND id != ?',
      whereArgs: [phone.trim(), excludeId ?? -1],
    );
    return result.isNotEmpty;
  }

  Future<Room?> getRoomById(int roomId) async {
    final db = await database;
    final maps = await db.query('rooms', where: 'id = ?', whereArgs: [roomId]);
    if (maps.isEmpty) return null;
    return Room.fromMap(maps.first);
  }

  Future<Customer?> getCustomerById(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Room>> getRoomsByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'rooms',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'id ASC',
    );
    return maps.map((e) => Room.fromMap(e)).toList();
  }
}
