import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/user.dart';
import '../../models/payment.dart';
import '../../models/order.dart';
import '../../models/collection.dart';
import '../../models/district.dart';
import '../../models/city.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _orderIdController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _totalController;
  late TextEditingController _deliveryChargeController;
  late TextEditingController _noteController;

  String? _selectedDistrict;
  String? _selectedCity;
  String? _merchantUsername;
  bool _isExpress = false;

  List<District> _districts = [];
  List<City> _cities = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadDistricts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.isMerchant ?? false) {
        setState(() => _merchantUsername = user!.username);
      } else if (user?.isAdmin ?? false) {
        context.read<AdminProvider>().loadUsers();
      }
    });
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _orderIdController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _totalController = TextEditingController();
    _deliveryChargeController = TextEditingController(text: '0');
    _noteController = TextEditingController();
  }

  Future<void> _loadDistricts() async {
    final result = await ApiService.getDistricts();
    if (result['success']) {
      setState(() {
        _districts =
            (result['data'] as List).map((d) => District.fromJson(d)).toList();
      });
    }
  }

  Future<void> _loadCities(String districtId) async {
    final result = await ApiService.getCities(districtId);
    if (result['success']) {
      setState(() {
        _cities =
            (result['data'] as List).map((c) => City.fromJson(c)).toList();
        _selectedCity = null;
      });
    }
  }

  void _handleCreateOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDistrict == null || _selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select location')),
        );
        return;
      }

      if (_merchantUsername == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a merchant')),
        );
        return;
      }
      final district = _districts.firstWhere(
        (item) => item.id == _selectedDistrict,
      );
      final success = await context.read<OrderProvider>().createOrder(
            orderId: _orderIdController.text.trim(),
            merchantUsername: _merchantUsername!,
            customerFirstName: _firstNameController.text,
            customerLastName: _lastNameController.text.isEmpty
                ? null
                : _lastNameController.text,
            customerPhone: _phoneController.text,
            district: district.nameEn,
            city: _selectedCity!,
            total: double.parse(_totalController.text),
            deliveryCharge: double.parse(_deliveryChargeController.text),
            isExpress: _isExpress,
            expressNote: _noteController.text,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.read<OrderProvider>().error ??
                  'Failed to create order')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _orderIdController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _totalController.dispose();
    _deliveryChargeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Order Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  hintText: 'Order ID',
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Order ID is required by the backend'
                    : null,
              ),
              const SizedBox(height: 12),
              Consumer2<AuthProvider, AdminProvider>(
                builder: (context, auth, admin, _) {
                  if (auth.currentUser?.isMerchant ?? false) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.storefront),
                      title: Text(auth.currentUser!.username),
                      subtitle: const Text('Merchant'),
                    );
                  }
                  final merchants =
                      admin.users.where((user) => user.isMerchant).toList();
                  return DropdownButtonFormField<String>(
                    value: _merchantUsername,
                    decoration: const InputDecoration(
                      hintText: 'Select Merchant',
                      prefixIcon: Icon(Icons.storefront),
                    ),
                    items: merchants
                        .map((merchant) => DropdownMenuItem(
                              value: merchant.username,
                              child: Text(merchant.fullName.trim().isEmpty
                                  ? merchant.username
                                  : '${merchant.fullName} (${merchant.username})'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _merchantUsername = value),
                    validator: (value) =>
                        value == null ? 'Merchant is required' : null,
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Customer Information'),
              const SizedBox(height: 12),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  hintText: 'First Name',
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  hintText: 'Last Name (optional)',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Phone is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Location'),
              const SizedBox(height: 12),

              // District Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: InputDecoration(
                  hintText: 'Select District',
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: _districts
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.nameEn),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedDistrict = value);
                  if (value != null) {
                    _loadCities(value);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a district';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // City Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  hintText: 'Select City',
                  prefixIcon: const Icon(Icons.location_on),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(
                          value: c.nameEn,
                          child: Text(c.nameEn),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCity = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Order Details'),
              const SizedBox(height: 12),

              // Total Amount
              TextFormField(
                controller: _totalController,
                decoration: InputDecoration(
                  hintText: 'Total Amount (LBP)',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Amount is required';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Delivery Charge
              TextFormField(
                controller: _deliveryChargeController,
                decoration: InputDecoration(
                  hintText: 'Delivery Charge (LBP)',
                  prefixIcon: const Icon(Icons.local_shipping),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (double.tryParse(value ?? '0') == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Additional Options'),
              const SizedBox(height: 12),

              // Express Checkbox
              CheckboxListTile(
                title: const Text('Express Delivery'),
                subtitle: const Text('Add urgent delivery flag'),
                value: _isExpress,
                onChanged: (value) {
                  setState(() => _isExpress = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),

              // Express Note
              if (_isExpress)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Express delivery note',
                        prefixIcon: const Icon(Icons.note),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer<OrderProvider>(
                  builder: (context, orderProvider, _) {
                    return ElevatedButton(
                      onPressed:
                          orderProvider.isLoading ? null : _handleCreateOrder,
                      child: orderProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Order'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
