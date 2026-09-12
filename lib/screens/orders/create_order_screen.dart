import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _totalController;
  late TextEditingController _deliveryChargeController;
  late TextEditingController _noteController;

  String? _selectedDistrict;
  String? _selectedCity;
  bool _isExpress = false;
  
  List<District> _districts = [];
  List<City> _cities = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadDistricts();
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
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
        _districts = (result['data'] as List)
            .map((d) => District.fromJson(d))
            .toList();
      });
    }
  }

  Future<void> _loadCities(String districtId) async {
    final result = await ApiService.getCities(districtId);
    if (result['success']) {
      setState(() {
        _cities = (result['data'] as List)
            .map((c) => City.fromJson(c))
            .toList();
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

      final success = await context.read<OrderProvider>().createOrder(
        customerFirstName: _firstNameController.text,
        customerLastName: _lastNameController.text.isEmpty ? null : _lastNameController.text,
        customerPhone: _phoneController.text,
        district: _selectedDistrict!,
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
          SnackBar(content: Text(context.read<OrderProvider>().error ?? 'Failed to create order')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
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
                      onPressed: orderProvider.isLoading ? null : _handleCreateOrder,
                      child: orderProvider.isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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