import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_empty_state.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _db.getAllCustomers();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  Future<void> _searchCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _db.searchCustomers(_searchQuery);
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditCustomerDialog({Customer? customer}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final nationalIdController = TextEditingController(
      text: customer?.nationalId ?? '',
    );
    final addressController = TextEditingController(
      text: customer?.address ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: AppConstants.rtlDirection,
          child: AlertDialog(
            title: Text(customer == null ? 'إضافة عميل' : 'تعديل العميل'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم العميل',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'يرجى إدخال اسم العميل'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'يرجى إدخال رقم الهاتف';
                        if (value.trim().length < 8)
                          return 'رقم الهاتف غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nationalIdController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهوية',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'يرجى إدخال رقم الهوية';
                        if (value.trim().length < 8)
                          return 'رقم الهوية غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'العنوان'),
                      maxLines: 3,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'يرجى إدخال العنوان'
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

                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  final nationalId = nationalIdController.text.trim();
                  final address = addressController.text.trim();

                  final exists = await _db.customerExistsByPhone(
                    phone,
                    excludeId: customer?.id,
                  );
                  if (exists) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('رقم الهاتف موجود بالفعل'),
                        ),
                      );
                    }
                    return;
                  }

                  if (customer == null) {
                    await _db.insertCustomer(
                      Customer(
                        name: name,
                        phone: phone,
                        nationalId: nationalId,
                        address: address,
                      ),
                    );
                  } else {
                    await _db.updateCustomer(
                      customer.copyWith(
                        name: name,
                        phone: phone,
                        nationalId: nationalId,
                        address: address,
                      ),
                    );
                  }

                  if (context.mounted) Navigator.pop(context, true);
                },
                child: Text(customer == null ? 'إضافة' : 'حفظ'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldSave == true) {
      await _loadCustomers();
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppConstants.rtlDirection,
        child: AlertDialog(
          title: const Text('حذف العميل'),
          content: Text('هل تريد حذف العميل ${customer.name}؟'),
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
    await _db.deleteCustomer(customer.id!);
    await _loadCustomers();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حذف العميل ${customer.name}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _customers
        : _customers.where((c) {
            final text = '${c.name} ${c.phone}'.toLowerCase();
            return text.contains(_searchQuery.toLowerCase());
          }).toList();

    return Directionality(
      textDirection: AppConstants.rtlDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditCustomerDialog(),
          backgroundColor: const Color(0xFF111827),
          icon: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Color(0XFFF4F7FB),
          ),
          label: const Text(
            'إضافة عميل',
            style: TextStyle(color: Color(0XFFF4F7FB)),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? const CustomEmptyState(
                  title: 'لا يوجد عملاء',
                  message: 'ابدأ بإضافة أول عميل في النظام.',
                  icon: Icons.people_alt_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10213A,
                              ).withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _searchCustomers();
                          },
                          textDirection: AppConstants.rtlDirection,
                          decoration: InputDecoration(
                            hintText: 'البحث بالاسم أو الهاتف',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...filtered.map((customer) {
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE5DD46),
                                      Color(0xFF0EA5E9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                      textDirection: AppConstants.rtlDirection,
                                    ),
                                    const SizedBox(height: 8),
                                    _CustomerInfoRow(
                                      icon: Icons.phone_rounded,
                                      value: customer.phone,
                                    ),
                                    const SizedBox(height: 6),
                                    _CustomerInfoRow(
                                      icon: Icons.badge_rounded,
                                      value: customer.nationalId,
                                    ),
                                    const SizedBox(height: 6),
                                    _CustomerInfoRow(
                                      icon: Icons.location_on_rounded,
                                      value: customer.address,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Color(0xFF475569),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showAddEditCustomerDialog(
                                      customer: customer,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteCustomer(customer);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('تعديل'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('حذف'),
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

  Widget _buildHeaderCard() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'العملاء',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  textDirection: AppConstants.rtlDirection,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_customers.length} عميل مسجل',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: AppConstants.rtlDirection,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loadCustomers,
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
    );
  }
}

class _CustomerInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CustomerInfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: AppConstants.rtlDirection,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
            textDirection: AppConstants.rtlDirection,
          ),
        ),
      ],
    );
  }
}
