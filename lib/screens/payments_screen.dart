import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/payment.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_empty_state.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final payments = await _db.getAllPayments();
    if (!mounted) return;
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    return Directionality(
      textDirection: AppConstants.rtlDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _payments.isEmpty
              ? const CustomEmptyState(
                  title: 'لا توجد دفعات',
                  message: 'عند إضافة دفعات إلى الحجوزات ستظهر هنا.',
                  icon: Icons.receipt_long,
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      _buildHeaderCard(totalAmount: totalAmount),
                      const SizedBox(height: 18),
                      ..._payments.map((payment) {
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
                          child: Row(
                            textDirection: AppConstants.rtlDirection,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.payments_rounded,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.customerName ?? 'عميل',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'الغرفة: ${payment.roomNumber ?? 'غير محدد'}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'طريقة الدفع: ${AppConstants.paymentMethodLabel(payment.paymentMethod)}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'التاريخ: ${payment.paymentDate.toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.currencyFormat(payment.amount),
                                    style: const TextStyle(
                                      color: Color(0xFF10213A),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textDirection: AppConstants.rtlDirection,
                                  ),
                                  const SizedBox(height: 8),
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
                                      AppConstants.paymentMethodLabel(
                                        payment.paymentMethod,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textDirection: AppConstants.rtlDirection,
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

  Widget _buildHeaderCard({required double totalAmount}) {
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
                'المدفوعات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                textDirection: AppConstants.rtlDirection,
              ),
              IconButton(
                tooltip: 'تحديث',
                onPressed: _loadPayments,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              textDirection: AppConstants.rtlDirection,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجمالي المدفوعات',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: AppConstants.rtlDirection,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.currencyFormat(totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                        textDirection: AppConstants.rtlDirection,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
