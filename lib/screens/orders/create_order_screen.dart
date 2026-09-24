import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/city.dart';
import '../../models/district.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalController = TextEditingController();
  final _deliveryChargeController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedCity;
  String? _merchantUsername;
  bool _isExpress = false;
  bool _loadingLocations = false;
  String? _locationError;
  List<District> _districts = [];
  List<City> _cities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.isMerchant ?? false) {
        setState(() => _merchantUsername = user!.username);
      } else if (user?.isAdmin ?? false) {
        context.read<AdminProvider>().loadUsers();
      }
      _loadDistricts();
    });
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _totalController.dispose();
    _deliveryChargeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() {
      _loadingLocations = true;
      _locationError = null;
    });
    final result = await ApiService.getDistricts();
    if (!mounted) return;
    if (result['success'] == true && result['data'] is List) {
      setState(() {
        _districts = (result['data'] as List)
            .whereType<Map>()
            .map((item) => District.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _loadingLocations = false;
      });
      return;
    }
    setState(() {
      _loadingLocations = false;
      _locationError =
          result['error']?.toString() ?? 'Locations could not be loaded.';
    });
  }

  Future<void> _loadCities(String districtId) async {
    setState(() {
      _loadingLocations = true;
      _locationError = null;
      _cities = [];
      _selectedCity = null;
    });
    final result = await ApiService.getCities(districtId);
    if (!mounted) return;
    if (result['success'] == true && result['data'] is List) {
      setState(() {
        _cities = (result['data'] as List)
            .whereType<Map>()
            .map(
              (item) => City.fromJson(
                Map<String, dynamic>.from(item),
                districtId: districtId,
              ),
            )
            .toList();
        _loadingLocations = false;
      });
      return;
    }
    setState(() {
      _loadingLocations = false;
      _locationError =
          result['error']?.toString() ?? 'Cities could not be loaded.';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null ||
        _selectedCity == null ||
        _merchantUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select a merchant and delivery location.')),
      );
      return;
    }
    final district =
        _districts.firstWhere((item) => item.id == _selectedDistrict);
    final success = await context.read<OrderProvider>().createOrder(
          orderId: _orderIdController.text.trim(),
          merchantUsername: _merchantUsername!,
          customerFirstName: _firstNameController.text.trim(),
          customerLastName: _lastNameController.text.trim().isEmpty
              ? null
              : _lastNameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          district: district.nameEn,
          city: _selectedCity!,
          total: double.parse(_totalController.text.trim()),
          deliveryCharge: double.parse(_deliveryChargeController.text.trim()),
          isExpress: _isExpress,
          expressNote: _noteController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully'),
          backgroundColor: AppColors.teal,
        ),
      );
      context.pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            context.read<OrderProvider>().error ?? 'Failed to create order'),
        backgroundColor: AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppContent(
            maxWidth: 980,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: 'Create order',
                    subtitle:
                        'Add customer, destination and payment details for a new delivery.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OrderMerchantFormSection(
                    orderIdController: _orderIdController,
                    merchantUsername: _merchantUsername,
                    onMerchantChanged: (value) =>
                        setState(() => _merchantUsername = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomerFormSection(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    phoneController: _phoneController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LocationFormSection(
                    districts: _districts,
                    cities: _cities,
                    selectedDistrict: _selectedDistrict,
                    selectedCity: _selectedCity,
                    loading: _loadingLocations,
                    error: _locationError,
                    onRetry: _loadDistricts,
                    onDistrictChanged: (value) {
                      setState(() => _selectedDistrict = value);
                      if (value != null) _loadCities(value);
                    },
                    onCityChanged: (value) =>
                        setState(() => _selectedCity = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PaymentFormSection(
                    totalController: _totalController,
                    deliveryChargeController: _deliveryChargeController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DeliveryOptionsSection(
                    isExpress: _isExpress,
                    noteController: _noteController,
                    onExpressChanged: (value) =>
                        setState(() => _isExpress = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer<OrderProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('create_order_submit_button'),
                          onPressed: provider.isLoading ? null : _submit,
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_box_outlined),
                          label: Text(provider.isLoading
                              ? 'Creating order…'
                              : 'Create order'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const FormSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.brandStrong, size: 21),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: AppSectionHeader(title: title, subtitle: subtitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class TwoColumnFields extends StatelessWidget {
  final Widget first;
  final Widget second;

  const TwoColumnFields({super.key, required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.compact) {
          return Column(
            children: [first, const SizedBox(height: AppSpacing.sm), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class OrderMerchantFormSection extends StatelessWidget {
  final TextEditingController orderIdController;
  final String? merchantUsername;
  final ValueChanged<String?> onMerchantChanged;

  const OrderMerchantFormSection({
    super.key,
    required this.orderIdController,
    required this.merchantUsername,
    required this.onMerchantChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Order information',
      subtitle: 'Backend order reference and merchant owner',
      icon: Icons.inventory_2_outlined,
      child: TwoColumnFields(
        first: TextFormField(
          key: const Key('create_order_id_field'),
          controller: orderIdController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Order ID',
            hintText: 'e.g. GD-10248',
            prefixIcon: Icon(Icons.tag_rounded),
          ),
          validator: requiredValidator('Order ID'),
        ),
        second: Consumer2<AuthProvider, AdminProvider>(
          builder: (context, auth, admin, child) {
            final current = auth.currentUser;
            if (current?.isMerchant ?? false) {
              return InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                child: Text(current!.username,
                    style: context.textStyles.titleSmall),
              );
            }
            final merchants =
                admin.users.where((user) => user.isMerchant).toList();
            return DropdownButtonFormField<String>(
              key: const Key('create_order_merchant_field'),
              initialValue: merchantUsername,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Merchant',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              items: merchants
                  .map(
                    (merchant) => DropdownMenuItem(
                      value: merchant.username,
                      child: Text(
                        merchant.fullName.trim().isEmpty
                            ? merchant.username
                            : '${merchant.fullName.trim()} · ${merchant.username}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onMerchantChanged,
              validator: (value) =>
                  value == null ? 'Merchant is required' : null,
            );
          },
        ),
      ),
    );
  }
}

class CustomerFormSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;

  const CustomerFormSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Customer',
      subtitle: 'Recipient name and contact number',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          TwoColumnFields(
            first: TextFormField(
              key: const Key('create_order_first_name_field'),
              controller: firstNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'First name',
                  prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: requiredValidator('First name'),
            ),
            second: TextFormField(
              controller: lastNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Last name (optional)',
                  prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('create_order_phone_field'),
            controller: phoneController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'e.g. 70 123 456',
                prefixIcon: Icon(Icons.phone_outlined)),
            validator: requiredValidator('Phone number'),
          ),
        ],
      ),
    );
  }
}

class LocationFormSection extends StatelessWidget {
  final List<District> districts;
  final List<City> cities;
  final String? selectedDistrict;
  final String? selectedCity;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onCityChanged;

  const LocationFormSection({
    super.key,
    required this.districts,
    required this.cities,
    required this.selectedDistrict,
    required this.selectedCity,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onDistrictChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Delivery location',
      subtitle: 'District and city from configured coverage',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          if (error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.red.withValues(alpha: .2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.red),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                      child: Text(error!, style: context.textStyles.bodySmall)),
                  TextButton(
                      onPressed: () => onRetry(), child: const Text('Retry')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TwoColumnFields(
            first: DropdownButtonFormField<String>(
              key: const Key('create_order_district_field'),
              initialValue: selectedDistrict,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'District',
                prefixIcon: const Icon(Icons.map_outlined),
                suffixIcon: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              items: districts
                  .map((district) => DropdownMenuItem(
                      value: district.id,
                      child: Text(district.nameEn,
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: loading ? null : onDistrictChanged,
              validator: (value) =>
                  value == null ? 'District is required' : null,
            ),
            second: DropdownButtonFormField<String>(
              key: const Key('create_order_city_field'),
              initialValue: selectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined)),
              items: cities
                  .map((city) => DropdownMenuItem(
                      value: city.nameEn,
                      child:
                          Text(city.nameEn, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged:
                  loading || selectedDistrict == null ? null : onCityChanged,
              validator: (value) => value == null ? 'City is required' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentFormSection extends StatelessWidget {
  final TextEditingController totalController;
  final TextEditingController deliveryChargeController;

  const PaymentFormSection({
    super.key,
    required this.totalController,
    required this.deliveryChargeController,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Payment',
      subtitle: 'Order value and delivery charge in Lebanese pounds',
      icon: Icons.payments_outlined,
      child: TwoColumnFields(
        first: TextFormField(
          key: const Key('create_order_total_field'),
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              labelText: 'Order total (LBP)',
              prefixIcon: Icon(Icons.payments_outlined)),
          validator: amountValidator(required: true),
        ),
        second: TextFormField(
          key: const Key('create_order_delivery_charge_field'),
          controller: deliveryChargeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Delivery charge (LBP)',
              prefixIcon: Icon(Icons.local_shipping_outlined)),
          validator: amountValidator(),
        ),
      ),
    );
  }
}

class DeliveryOptionsSection extends StatelessWidget {
  final bool isExpress;
  final TextEditingController noteController;
  final ValueChanged<bool> onExpressChanged;

  const DeliveryOptionsSection({
    super.key,
    required this.isExpress,
    required this.noteController,
    required this.onExpressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Delivery options',
      subtitle: 'Prioritize urgent deliveries when needed',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('create_order_express_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Express delivery'),
            subtitle: const Text(
                'Highlight this order as urgent for operations and the driver.'),
            secondary: const Icon(Icons.bolt_rounded, color: AppColors.amber),
            value: isExpress,
            onChanged: onExpressChanged,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: isExpress
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextFormField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Express note (optional)',
                        hintText:
                            'Add delivery instructions or urgency context',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

FormFieldValidator<String> requiredValidator(String label) {
  return (value) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;
}

FormFieldValidator<String> amountValidator({bool required = false}) {
  return (value) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) return 'Enter a valid amount';
    if (amount < 0) return 'Amount cannot be negative';
    return null;
  };
}
