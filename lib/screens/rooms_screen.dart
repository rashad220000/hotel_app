import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/room.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_empty_state.dart';
import '../widgets/room_card.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final rooms = await _db.getAllRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditRoomDialog({Room? room}) async {
    final formKey = GlobalKey<FormState>();
    final roomNumberController = TextEditingController(
      text: room?.roomNumber ?? '',
    );
    final roomTypeController = TextEditingController(
      text: room?.roomType ?? 'غرفة فردية',
    );
    final priceController = TextEditingController(
      text: room != null ? room.price.toString() : '',
    );
    final descriptionController = TextEditingController(
      text: room?.description ?? '',
    );
    String status = room?.status ?? AppConstants.roomStatusAvailable;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: AppConstants.rtlDirection,
          child: AlertDialog(
            title: Text(room == null ? 'إضافة غرفة' : 'تعديل الغرفة'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: roomNumberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الغرفة',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'يرجى إدخال رقم الغرفة'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: roomTypeController.text.isNotEmpty
                          ? roomTypeController.text
                          : AppConstants.roomTypes.first,
                      decoration: const InputDecoration(
                        labelText: 'نوع الغرفة',
                      ),
                      items: AppConstants.roomTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) roomTypeController.text = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'السعر'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'يرجى إدخال السعر';
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0)
                          return 'السعر غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'الحالة'),
                      items:
                          [
                            AppConstants.roomStatusAvailable,
                            AppConstants.roomStatusBooked,
                            AppConstants.roomStatusMaintenance,
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(AppConstants.roomStatusLabel(item)),
                            );
                          }).toList(),
                      onChanged: (value) => status = value ?? status,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'الوصف'),
                      maxLines: 3,
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
                  final roomNumber = roomNumberController.text.trim();
                  final roomType = roomTypeController.text.trim();
                  final price = double.tryParse(priceController.text.trim());
                  final description = descriptionController.text.trim();

                  final exists = await _db.roomNumberExists(
                    roomNumber,
                    excludeId: room?.id,
                  );
                  if (exists && room == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('رقم الغرفة موجود بالفعل'),
                        ),
                      );
                    }
                    return;
                  }

                  if (room == null) {
                    final newRoom = Room(
                      roomNumber: roomNumber,
                      roomType: roomType,
                      price: price ?? 0,
                      status: status,
                      description: description,
                    );
                    await _db.insertRoom(newRoom);
                  } else {
                    final updatedRoom = room.copyWith(
                      roomNumber: roomNumber,
                      roomType: roomType,
                      price: price ?? room.price,
                      status: status,
                      description: description,
                    );
                    await _db.updateRoom(updatedRoom);
                  }

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(room == null ? 'إضافة' : 'حفظ'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldSave == true) {
      await _loadRooms();
    }
  }

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الغرفة'),
          content: Text('هل تريد حذف غرفة رقم ${room.roomNumber}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.deleteRoom(room.id!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الغرفة بنجاح')));
      }
      await _loadRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل حذف الغرفة: $e')));
      }
    }
  }

  Future<void> _changeRoomStatus(Room room) async {
    final nextStatus = switch (room.status) {
      AppConstants.roomStatusAvailable => AppConstants.roomStatusBooked,
      AppConstants.roomStatusBooked => AppConstants.roomStatusMaintenance,
      AppConstants.roomStatusMaintenance => AppConstants.roomStatusAvailable,
      _ => AppConstants.roomStatusAvailable,
    };

    final updated = room.copyWith(status: nextStatus);
    await _db.updateRoom(updated);
    await _loadRooms();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تغيير حالة الغرفة إلى ${AppConstants.roomStatusLabel(nextStatus)}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = _rooms
        .where((room) => room.status == AppConstants.roomStatusAvailable)
        .length;
    final bookedCount = _rooms
        .where((room) => room.status == AppConstants.roomStatusBooked)
        .length;
    final maintenanceCount = _rooms
        .where((room) => room.status == AppConstants.roomStatusMaintenance)
        .length;

    return Directionality(
      textDirection: AppConstants.rtlDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditRoomDialog(),
          backgroundColor: const Color(0xFF111827),
          icon: const Icon(Icons.add_rounded, color: Color(0xFFFFFFFF)),
          label: const Text(
            'إضافة غرفة',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rooms.isEmpty
              ? const CustomEmptyState(
                  title: 'لا توجد غرف',
                  message: 'ابدأ بإضافة أول غرفة في الفندق.',
                  icon: Icons.hotel,
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    children: [
                      _buildHeaderCard(
                        availableCount: availableCount,
                        bookedCount: bookedCount,
                        maintenanceCount: maintenanceCount,
                      ),
                      const SizedBox(height: 18),
                      ..._rooms.map(
                        (room) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: RoomCard(
                            room: room,
                            onEdit: () => _showAddEditRoomDialog(room: room),
                            onDelete: () => _deleteRoom(room),
                            onStatusChange: () => _changeRoomStatus(room),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required int availableCount,
    required int bookedCount,
    required int maintenanceCount,
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
                'إدارة الغرف',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                textDirection: AppConstants.rtlDirection,
              ),
              IconButton(
                tooltip: 'تحديث',
                onPressed: _loadRooms,
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
                label: 'متاحة',
                value: '$availableCount',
                color: const Color(0xFF34D399),
              ),
              const SizedBox(width: 10),
              _SummaryPill(
                label: 'محجوزة',
                value: '$bookedCount',
                color: const Color(0xFFFBBF24),
              ),
              const SizedBox(width: 10),
              _SummaryPill(
                label: 'صيانة',
                value: '$maintenanceCount',
                color: const Color(0xFFF87171),
              ),
            ],
          ),
        ],
      ),
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
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
