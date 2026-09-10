import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/booking.dart';

import '../models/payment.dart';

import '../utils/app_constants.dart';
import '../widgets/custom_empty_state.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _db.getAllBookings();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  Future<void> _showAddBookingDialog() async {
    final formKey = GlobalKey<FormState>();
    final customerIdController = TextEditingController();
    final roomIdController = TextEditingController();
    final checkInController = TextEditingController();
    final checkOutController = TextEditingController();
    DateTime? checkIn;
    DateTime? checkOut;

    final customers = await _db.getAllCustomers();
    final rooms = await _db.getAvailableRooms();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: AppConstants.rtlDirection,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('إنشاء حجز جديد'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: customers.isNotEmpty
                              ? customers.first.id
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'العميل',
                          ),
                          items: customers
                              .map(
                                (customer) => DropdownMenuItem<int>(
                                  value: customer.id,
                                  child: Text(customer.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => customerIdController.text =
                              value?.toString() ?? '',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: rooms.isNotEmpty ? rooms.first.id : null,
                          decoration: const InputDecoration(
                            labelText: 'الغرفة',
                          ),
                          items: rooms
                              .map(
                                (room) => DropdownMenuItem<int>(
                                  value: room.id,
                                  child: Text(
                                    'غرفة ${room.roomNumber} - ${room.roomType}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              roomIdController.text = value?.toString() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: checkInController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الدخول',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              checkIn = picked;
                              checkInController.text = _dateFormat.format(
                                picked,
                              );
                              setStateDialog(() {});
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'يرجى اختيار تاريخ الدخول'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: checkOutController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الخروج',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              checkOut = picked;
                              checkOutController.text = _dateFormat.format(
                                picked,
                              );
                              setStateDialog(() {});
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'يرجى اختيار تاريخ الخروج'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final customerIdText = customerIdController.text.trim();
                      final roomIdText = roomIdController.text.trim();

                      if (customerIdText.isEmpty || roomIdText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يجب اختيار العميل والغرفة'),
                          ),
                        );
                        return;
                      }

                      final customerId = int.tryParse(customerIdText);
                      final roomId = int.tryParse(roomIdText);

                      if (customerId == null || roomId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('بيانات الحجز غير صحيحة'),
                          ),
                        );
                        return;
                      }

                      final selectedCheckIn = checkIn ?? DateTime.now();
                      final selectedCheckOut =
                          checkOut ??
                          DateTime.now().add(const Duration(days: 1));

                      if (!selectedCheckOut.isAfter(selectedCheckIn)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'يجب أن يكون تاريخ الخروج بعد تاريخ الدخول',
                            ),
                          ),
                        );
                        return;
                      }

                      final room = await _db.getRoomById(roomId);
                      if (room == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الغرفة غير موجودة')),
                        );
                        return;
                      }

                      if (room.status != AppConstants.roomStatusAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('لا يمكن حجز غرفة غير متاحة'),
                          ),
                        );
                        return;
                      }

                      final numberOfNights = selectedCheckOut
                          .difference(selectedCheckIn)
                          .inDays;
                      final totalPrice = room.price * numberOfNights;

                      final booking = Booking(
                        customerId: customerId,
                        roomId: roomId,
                        checkIn: selectedCheckIn,
                        checkOut: selectedCheckOut,
                        numberOfNights: numberOfNights,
                        totalPrice: totalPrice,
                        status: AppConstants.bookingStatusActive,
                        createdAt: DateTime.now(),
                      );

                      await _db.createBookingWithRoomUpdate(
                        booking: booking,
                        roomId: roomId,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    child: const Text('حفظ الحجز'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (shouldSave == true) await _loadBookings();
  }

  Future<void> _completeBooking(Booking booking) async {
    final room = await _db.getRoomById(booking.roomId);
    if (room == null) return;
    await _db.completeOrCancelBooking(
      bookingId: booking.id!,
      roomId: booking.roomId,
      status: AppConstants.bookingStatusCompleted,
    );
    await _loadBookings();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنهاء الحجز بنجاح')));
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppConstants.rtlDirection,
        child: AlertDialog(
          title: const Text('إلغاء الحجز'),
          content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await _db.completeOrCancelBooking(
      bookingId: booking.id!,
      roomId: booking.roomId,
      status: AppConstants.bookingStatusCancelled,
    );
    await _loadBookings();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز')));
    }
  }

  Future<void> _navigateToDetails(Booking booking) async {
    final details = await _db.getBookingById(booking.id!);
    if (details == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: details),
      ),
    );
    await _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _bookings
        .where((booking) => booking.status == AppConstants.bookingStatusActive)
        .length;
    final completedCount = _bookings
        .where(
          (booking) => booking.status == AppConstants.bookingStatusCompleted,
        )
        .length;
    final cancelledCount = _bookings
        .where(
          (booking) => booking.status == AppConstants.bookingStatusCancelled,
        )
        .length;

    return Directionality(
      textDirection: AppConstants.rtlDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddBookingDialog,
          backgroundColor: const Color(0xFF111827),
          icon: const Icon(Icons.add_rounded, color: Color(0XFFF4F7FB)),
          label: const Text(
            'إنشاء حجز',
            style: TextStyle(color: Color(0XFFF4F7FB)),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
              ? const CustomEmptyState(
                  title: 'لا توجد حجوزات',
                  message: 'يمكنك إنشاء أول حجز من الفندق.',
                  icon: Icons.calendar_month_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    children: [
                      _buildHeaderCard(
                        activeCount: activeCount,
                        completedCount: completedCount,
                        cancelledCount: cancelledCount,
                      ),
                      const SizedBox(height: 18),
                      ..._bookings.map((booking) {
                        final statusColor =
                            booking.status == AppConstants.bookingStatusActive
                            ? const Color(0xFF10B981)
                            : booking.status ==
                                  AppConstants.bookingStatusCompleted
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF4444);

                        final statusBg =
                            booking.status == AppConstants.bookingStatusActive
                            ? const Color(0xFFE7F9F1)
                            : booking.status ==
                                  AppConstants.bookingStatusCompleted
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFFEF2F2);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10213A,
                                ).withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      booking.customerName ?? 'عميل',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      AppConstants.bookingStatusLabel(
                                        booking.status,
                                      ),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _BookingMetaRow(
                                icon: Icons.meeting_room_rounded,
                                label: 'الغرفة',
                                value:
                                    '${booking.roomNumber ?? booking.roomId}',
                              ),
                              const SizedBox(height: 8),
                              _BookingMetaRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'الدخول',
                                value: _dateFormat.format(booking.checkIn),
                              ),
                              const SizedBox(height: 8),
                              _BookingMetaRow(
                                icon: Icons.calendar_month_rounded,
                                label: 'الخروج',
                                value: _dateFormat.format(booking.checkOut),
                              ),
                              const SizedBox(height: 8),
                              _BookingMetaRow(
                                icon: Icons.nights_stay_rounded,
                                label: 'الليالي',
                                value: '${booking.numberOfNights}',
                              ),
                              const SizedBox(height: 8),
                              _BookingMetaRow(
                                icon: Icons.attach_money_rounded,
                                label: 'الإجمالي',
                                value: AppConstants.currencyFormat(
                                  booking.totalPrice,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _navigateToDetails(booking),
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('التفاصيل'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF10213A),
                                      side: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  if (booking.status ==
                                      AppConstants.bookingStatusActive)
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _completeBooking(booking),
                                      icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('إنهاء'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF10B981),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (booking.status ==
                                      AppConstants.bookingStatusActive)
                                    OutlinedButton.icon(
                                      onPressed: () => _cancelBooking(booking),
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('إلغاء'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFEF4444),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required int activeCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحجوزات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                textDirection: AppConstants.rtlDirection,
              ),
              IconButton(
                tooltip: 'تحديث',
                onPressed: _loadBookings,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            textDirection: AppConstants.rtlDirection,
            children: [
              _SummaryPill(
                label: 'نشطة',
                value: '$activeCount',
                color: const Color(0xFF34D399),
              ),
              const SizedBox(width: 10),
              _SummaryPill(
                label: 'مكتملة',
                value: '$completedCount',
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 10),
              _SummaryPill(
                label: 'ملغية',
                value: '$cancelledCount',
                color: const Color(0xFFF87171),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BookingMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: AppConstants.rtlDirection,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          textDirection: AppConstants.rtlDirection,
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF10213A),
              fontWeight: FontWeight.w700,
            ),
            textDirection: AppConstants.rtlDirection,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            textDirection: AppConstants.rtlDirection,
          ),
        ],
      ),
    );
  }
}

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = AppConstants.paymentMethodCash;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await _db.getPaymentsByBookingId(widget.booking.id!);
    if (!mounted) return;
    setState(() {
      _payments = payments.map((payment) => payment.toMap()).toList();
      _isLoading = false;
    });
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ دفع صحيح')));
      return;
    }

    final payment = paymentFromBooking(
      bookingId: widget.booking.id!,
      amount: amount,
      method: _paymentMethod,
      notes: _notesController.text.trim(),
    );

    await _db.insertPayment(payment);
    _amountController.clear();
    _notesController.clear();
    await _loadPayments();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ الدفعة بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = _payments.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
    final remaining = widget.booking.totalPrice - totalPaid;

    return Directionality(
      textDirection: AppConstants.rtlDirection,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'العميل: ${widget.booking.customerName ?? 'غير معروف'}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'الغرفة: ${widget.booking.roomNumber ?? widget.booking.roomId}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'تاريخ الدخول: ${widget.booking.checkIn.toLocal().toString().split(' ')[0]}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'تاريخ الخروج: ${widget.booking.checkOut.toLocal().toString().split(' ')[0]}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'عدد الليالي: ${widget.booking.numberOfNights}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'إجمالي الحجز: ${AppConstants.currencyFormat(widget.booking.totalPrice)}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'المدفوعات: ${AppConstants.currencyFormat(totalPaid)}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                            Text(
                              'المتبقي: ${AppConstants.currencyFormat(remaining)}',
                              textDirection: AppConstants.rtlDirection,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'المبلغ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'طريقة الدفع',
                              ),
                              items: AppConstants.paymentMethods
                                  .map(
                                    (method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(
                                        AppConstants.paymentMethodLabel(method),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                () => _paymentMethod = value ?? _paymentMethod,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _addPayment,
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('إضافة دفعة'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'سجل المدفوعات',
                      style: Theme.of(context).textTheme.titleLarge,
                      textDirection: AppConstants.rtlDirection,
                    ),
                    const SizedBox(height: 8),
                    if (_payments.isEmpty)
                      const CustomEmptyState(
                        title: 'لا توجد دفعات',
                        message: 'لم يتم تسجيل أي دفعات لهذا الحجز.',
                        icon: Icons.receipt_long,
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          final item = Payment.fromMap(payment);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                '${AppConstants.currencyFormat(item.amount)}',
                                textDirection: AppConstants.rtlDirection,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'طريقة الدفع: ${AppConstants.paymentMethodLabel(item.paymentMethod)}',
                                    textDirection: AppConstants.rtlDirection,
                                  ),
                                  Text(
                                    'التاريخ: ${item.paymentDate.toLocal().toString().split(' ')[0]}',
                                    textDirection: AppConstants.rtlDirection,
                                  ),
                                  if (item.notes.isNotEmpty)
                                    Text(
                                      'ملاحظات: ${item.notes}',
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

Payment paymentFromBooking({
  required int bookingId,
  required double amount,
  required String method,
  required String notes,
}) {
  return Payment(
    bookingId: bookingId,
    amount: amount,
    paymentDate: DateTime.now(),
    paymentMethod: method,
    notes: notes,
  );
}
