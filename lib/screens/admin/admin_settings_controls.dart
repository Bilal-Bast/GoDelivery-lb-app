import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';

const deliveryChargeRegions = [
  'Akkar',
  'Baalbek-Hermel',
  'Beirut',
  'Bekaa',
  'El Nabatieh',
  'Mount Lebanon',
  'North',
  'South',
];

class AdminSettingsControls extends StatefulWidget {
  final AdminProvider provider;
  const AdminSettingsControls({super.key, required this.provider});

  @override
  State<AdminSettingsControls> createState() => _AdminSettingsControlsState();
}

class _AdminSettingsControlsState extends State<AdminSettingsControls> {
  final _cityEn = TextEditingController();
  final _cityAr = TextEditingController();
  final Map<String, TextEditingController> _charges = {
    for (final region in deliveryChargeRegions) region: TextEditingController(),
  };
  String? _district;
  String? _merchant;
  String? _validationError;

  @override
  void dispose() {
    _cityEn.dispose();
    _cityAr.dispose();
    for (final controller in _charges.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchants =
        widget.provider.users.where((user) => user.isMerchant).toList();
    return Column(children: [
      AppSurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionHeader(
            title: 'Add city',
            subtitle: 'Add bilingual city data to an existing district',
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _district,
            decoration: const InputDecoration(labelText: 'District'),
            items: widget.provider.locations
                .map((district) => DropdownMenuItem(
                      value: district.nameEn,
                      child: Text(district.nameEn),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _district = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _cityEn,
            decoration: const InputDecoration(labelText: 'City name (English)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _cityAr,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'City name (Arabic)'),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.provider.mutationBusy || _district == null
                  ? null
                  : _addCity,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add city'),
            ),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppSurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionHeader(
            title: 'Merchant delivery charges',
            subtitle: 'Authoritative regional prices in USD',
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _merchant,
            decoration: const InputDecoration(labelText: 'Merchant'),
            items: merchants
                .map((merchant) => DropdownMenuItem(
                      value: merchant.id,
                      child:
                          Text('${merchant.fullName} (${merchant.username})'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _merchant = value);
              if (value == null) return;
              final merchant = merchants.firstWhere((user) => user.id == value);
              for (final region in deliveryChargeRegions) {
                _charges[region]!.text =
                    (merchant.deliveryCharges[region] ?? 0).toStringAsFixed(2);
              }
            },
          ),
          if (_merchant != null) ...[
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth >= 680
                  ? (constraints.maxWidth - AppSpacing.md) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final region in deliveryChargeRegions)
                    SizedBox(
                      width: width,
                      child: TextField(
                        controller: _charges[region],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: '$region (USD)',
                          prefixText: r'$ ',
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: widget.provider.mutationBusy
                    ? null
                    : () => _saveCharges(merchants),
                child: const Text('Save charges'),
              ),
            ),
          ],
          if (widget.provider.mutationError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(widget.provider.mutationError!,
                  style: TextStyle(color: context.colors.error)),
            ),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(_validationError!,
                  style: TextStyle(color: context.colors.error)),
            ),
        ]),
      ),
    ]);
  }

  Future<void> _addCity() async {
    final cityEn = _cityEn.text.trim();
    if (cityEn.isEmpty) {
      setState(() => _validationError = 'English city name is required');
      return;
    }
    setState(() => _validationError = null);
    final success = await widget.provider.addLocation(
      _district!,
      cityEn,
      _cityAr.text.trim(),
    );
    if (success) {
      _cityEn.clear();
      _cityAr.clear();
    }
  }

  Future<void> _saveCharges(List<User> merchants) async {
    final merchant = merchants.firstWhere((user) => user.id == _merchant);
    final charges = <String, double>{};
    for (final region in deliveryChargeRegions) {
      final value = double.tryParse(_charges[region]!.text.trim());
      if (value == null || value < 0) {
        setState(() => _validationError =
            '$region must be a valid non-negative USD amount');
        return;
      }
      charges[region] = value;
    }
    setState(() => _validationError = null);
    await widget.provider.updateMerchantCharges(merchant, charges);
  }
}
