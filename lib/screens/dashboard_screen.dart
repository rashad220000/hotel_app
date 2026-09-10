import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../utils/app_constants.dart';
import '../widgets/dashboard_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Map<String, dynamic> stats = {
    'totalRooms': 0,
    'availableRooms': 0,
    'bookedRooms': 0,
    'maintenanceRooms': 0,
    'activeBookings': 0,
    'totalPayments': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await _db.getDashboardStats();
      if (!mounted) return;
      setState(() {
        stats = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تحميل الإحصائيات: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final cards = [
      DashboardCard(
        title: 'إجمالي الغرف',
        value: '${stats['totalRooms']}',
        icon: Icons.meeting_room_rounded,
        color: const Color(0xFF4F46E5),
      ),
      DashboardCard(
        title: 'الغرف المتاحة',
        value: '${stats['availableRooms']}',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
      ),
      DashboardCard(
        title: 'الغرف المحجوزة',
        value: '${stats['bookedRooms']}',
        icon: Icons.event_busy_rounded,
        color: const Color(0xFFF59E0B),
      ),
      DashboardCard(
        title: 'تحت الصيانة',
        value: '${stats['maintenanceRooms']}',
        icon: Icons.build_circle_rounded,
        color: const Color(0xFFEF4444),
      ),
      DashboardCard(
        title: 'الحجوزات النشطة',
        value: '${stats['activeBookings']}',
        icon: Icons.book_online_rounded,
        color: const Color(0xFF06B6D4),
      ),
      DashboardCard(
        title: 'إجمالي المدفوعات',
        value: AppConstants.currencyFormat(
          (stats['totalPayments'] as num).toDouble(),
        ),
        icon: Icons.payments_rounded,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    final formattedDate = DateFormat(
      'EEEE، d MMMM',
      'ar',
    ).format(DateTime.now());

    return Directionality(
      textDirection: AppConstants.rtlDirection,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPremiumHeader(context, formattedDate),
                const SizedBox(height: 22),
                _buildSummaryBar(context),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 12.0;
                    final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                    final itemWidth =
                        (constraints.maxWidth -
                            spacing * (crossAxisCount - 1)) /
                        crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(cards.length, (index) {
                        return SizedBox(width: itemWidth, child: cards[index]);
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, String formattedDate) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
            const Color(0xFF334155),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'محدث الآن',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: AppConstants.rtlDirection,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.notifications_none_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            textDirection: AppConstants.rtlDirection,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة التحكم',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textDirection: AppConstants.rtlDirection,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      textDirection: AppConstants.rtlDirection,
                    ),
                  ],
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.hotel_class_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context) {
    final totalRooms = (stats['totalRooms'] as num).toInt();
    final availableRooms = (stats['availableRooms'] as num).toInt();
    final bookedRooms = (stats['bookedRooms'] as num).toInt();

    final occupancyRate = totalRooms > 0
        ? ((bookedRooms / totalRooms) * 100).clamp(0, 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
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
                'نظرة عامة على الفندق',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textDirection: AppConstants.rtlDirection,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$occupancyRate% إشغال',
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: AppConstants.rtlDirection,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalRooms > 0 ? bookedRooms / totalRooms : 0,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            textDirection: AppConstants.rtlDirection,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryMetric('المتاحة', '$availableRooms', Colors.green),
              _buildSummaryMetric('المحجوزة', '$bookedRooms', Colors.amber),
              _buildSummaryMetric('الإجمالي', '$totalRooms', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          textDirection: AppConstants.rtlDirection,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
          textDirection: AppConstants.rtlDirection,
        ),
      ],
    );
  }
}
