import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'نظام إدارة الفندق';
  static const String dbName = 'hotel.db';

  static TextDirection get rtlDirection =>
      TextDirection.values.firstWhere((direction) => direction.name == 'rtl');

  static const String roomStatusAvailable = 'available';
  static const String roomStatusBooked = 'booked';
  static const String roomStatusMaintenance = 'maintenance';

  static const String bookingStatusActive = 'active';
  static const String bookingStatusCompleted = 'completed';
  static const String bookingStatusCancelled = 'cancelled';

  static const String paymentMethodCash = 'cash';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodTransfer = 'transfer';

  static const List<String> roomTypes = [
    'غرفة فردية',
    'غرفة مزدوجة',
    'جناح',
    'غرفة عائلية',
  ];

  static const List<String> paymentMethods = [
    paymentMethodCash,
    paymentMethodCard,
    paymentMethodTransfer,
  ];

  static String roomStatusLabel(String status) {
    switch (status) {
      case roomStatusAvailable:
        return 'متاحة';
      case roomStatusBooked:
        return 'محجوزة';
      case roomStatusMaintenance:
        return 'تحت الصيانة';
      default:
        return 'غير معروف';
    }
  }

  static String bookingStatusLabel(String status) {
    switch (status) {
      case bookingStatusActive:
        return 'نشط';
      case bookingStatusCompleted:
        return 'مكتمل';
      case bookingStatusCancelled:
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  static String paymentMethodLabel(String method) {
    switch (method) {
      case paymentMethodCash:
        return 'نقداً';
      case paymentMethodCard:
        return 'بطاقة';
      case paymentMethodTransfer:
        return 'تحويل';
      default:
        return 'غير معروف';
    }
  }

  static String currencyFormat(double amount) {
    return '${amount.toStringAsFixed(2)} ر.س';
  }

  static bool isValidPhone(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 8 && trimmed.length <= 15;
  }

  static bool isValidNationalId(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 8 && trimmed.length <= 15;
  }
}
