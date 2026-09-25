import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/user.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';

class AdminUsersPage extends StatefulWidget {
  final AdminProvider provider;
  final Future<void> Function() onRefresh;

  const AdminUsersPage({
    super.key,
    required this.provider,
    required this.onRefresh,
  });

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _search = TextEditingController();
  String _role = 'ALL';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final users = widget.provider.users.where((user) {
      final roleMatches = _role == 'ALL' || user.role.toUpperCase() == _role;
      final searchMatches = query.isEmpty ||
          user.username.toLowerCase().contains(query) ||
          user.fullName.toLowerCase().contains(query) ||
          (user.email ?? '').toLowerCase().contains(query);
      return roleMatches && searchMatches;
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            AppPageHeader(
              title: 'Users',
              subtitle:
                  'Authoritative administrator, driver and merchant accounts',
              actions: [
                FilledButton.icon(
                  onPressed: widget.provider.mutationBusy
                      ? null
                      : () => _openEditor(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add user'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppSurfaceCard(
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: wide ? 440 : double.infinity,
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Search accounts',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: wide ? 220 : double.infinity,
                    child: DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const ['ALL', 'ADMIN', 'DRIVER', 'MERCHANT']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _role = value!),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.provider.mutationError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(widget.provider.mutationError!,
                  style: TextStyle(color: context.colors.error)),
            ],
            const SizedBox(height: AppSpacing.md),
            if (users.isEmpty)
              const AppSurfaceCard(
                child: AppEmptyState(
                  title: 'No matching accounts',
                  message: 'Change the search or role filter and try again.',
                ),
              )
            else
              for (final user in users) ...[
                AppSurfaceCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(child: _UserSummary(user: user)),
                      PopupMenuButton<String>(
                        enabled: !widget.provider.mutationBusy,
                        onSelected: (action) =>
                            _handleAction(context, user, action),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Edit account')),
                          PopupMenuItem(
                              value: 'password', child: Text('Reset password')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete account')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        );
      }),
    );
  }

  Future<void> _handleAction(
      BuildContext context, User user, String action) async {
    if (action == 'edit') return _openEditor(context, user: user);
    if (action == 'password') return _resetPassword(context, user);
    if (action == 'delete') return _delete(context, user);
  }

  Future<void> _openEditor(BuildContext context, {User? user}) async {
    final result = await showDialog<_UserSubmission>(
      context: context,
      builder: (_) => _UserEditorDialog(user: user),
    );
    if (result == null || !mounted) return;
    final success = user == null
        ? await widget.provider.createUser(result.role, result.common)
        : await widget.provider.updateUserAccount(
            user,
            result.common,
            roleChanges: result.roleSpecific,
          );
    if (success &&
        user != null &&
        user.isMerchant &&
        result.legacyBalance != null &&
        result.legacyBalance != user.legacyBalance) {
      await widget.provider.updateMerchantLegacyBalance(
        user,
        result.legacyBalance!,
      );
    }
  }

  Future<void> _resetPassword(BuildContext context, User user) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset ${user.username} password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reset password'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.length < 6) return;
    await widget.provider.resetUserPassword(user.id, password);
  }

  Future<void> _delete(BuildContext context, User user) async {
    final preview = await widget.provider.getDeletePreview(user.id);
    if (!context.mounted) return;
    if (preview['success'] != true) {
      _message(preview['error']?.toString() ?? 'Unable to inspect account');
      return;
    }
    final data = preview['data'] is Map
        ? Map<String, dynamic>.from(preview['data'] as Map)
        : preview;
    final blockers =
        data['blockers'] is List ? data['blockers'] as List : const [];
    if (data['canDelete'] != true) {
      _message(blockers
          .whereType<Map>()
          .map((item) => item['label']?.toString())
          .whereType<String>()
          .join('\n'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text('Delete ${user.username}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await widget.provider.deleteUserAccount(user.id);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(message.isEmpty ? 'Account cannot be deleted' : message)),
      );
}

class _UserSummary extends StatelessWidget {
  final User user;
  const _UserSummary({required this.user});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.fullName.trim().isEmpty ? user.username : user.fullName.trim(),
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall,
          ),
          Text('@${user.username} • ${user.role.toUpperCase()}',
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall),
          if (user.email?.isNotEmpty == true)
            Text(user.email!, overflow: TextOverflow.ellipsis),
          if (user.isDriver && user.deliveryFee != null)
            Text('Delivery fee ${formatUsd(user.deliveryFee!)}'),
          if (user.isMerchant)
            Text(
              '${user.accountType?.toUpperCase() ?? 'UNCONFIGURED'} • legacy ${formatUsd(user.legacyBalance)}',
            ),
        ],
      );
}

class _UserSubmission {
  final String role;
  final Map<String, dynamic> common;
  final Map<String, dynamic> roleSpecific;
  final double? legacyBalance;

  const _UserSubmission(
      this.role, this.common, this.roleSpecific, this.legacyBalance);
}

class _UserEditorDialog extends StatefulWidget {
  final User? user;
  const _UserEditorDialog({this.user});

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  final _key = GlobalKey<FormState>();
  late String _role;
  late String _accountType;
  late final Map<String, TextEditingController> _fields;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _role = user?.role.toUpperCase() ?? 'ADMIN';
    _accountType = user?.accountType?.toUpperCase() ?? 'POSTPAID';
    _fields = {
      'username': TextEditingController(text: user?.username),
      'email': TextEditingController(text: user?.email),
      'password': TextEditingController(),
      'firstName': TextEditingController(text: user?.firstName),
      'lastName': TextEditingController(text: user?.lastName),
      'phone': TextEditingController(text: user?.phone),
      'deliveryFee': TextEditingController(text: user?.deliveryFee?.toString()),
      'legacyBalance':
          TextEditingController(text: user?.legacyBalance.toString() ?? '0'),
      'paymentDay': TextEditingController(text: user?.paymentDay),
      'orderIdPrefix': TextEditingController(text: user?.orderIdPrefix),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.user == null ? 'Create user' : 'Edit user'),
        content: SizedBox(
          width: 620,
          child: Form(
            key: _key,
            child: SingleChildScrollView(
              child: Column(children: [
                if (widget.user == null)
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const ['ADMIN', 'DRIVER', 'MERCHANT']
                        .map((role) =>
                            DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (value) => setState(() => _role = value!),
                  ),
                _field('username', 'Username', required: true),
                _field('email', 'Email', required: true),
                if (widget.user == null)
                  _field('password', 'Initial password',
                      required: true, obscure: true),
                _field('firstName', 'First name', required: true),
                _field('lastName', 'Last name'),
                _field('phone', 'Phone', required: true),
                if (_role == 'DRIVER')
                  _field('deliveryFee', 'Delivery fee (USD)', numeric: true),
                if (_role == 'MERCHANT') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _accountType,
                    decoration:
                        const InputDecoration(labelText: 'Account type'),
                    items: const ['PREPAID', 'POSTPAID']
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _accountType = value!),
                  ),
                  if (_accountType == 'POSTPAID')
                    _field('paymentDay', 'Payment day', required: true),
                  _field('orderIdPrefix', 'Order ID prefix'),
                  if (widget.user != null && _accountType == 'PREPAID')
                    _field('legacyBalance', 'Legacy balance (USD)',
                        numeric: true),
                ],
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _submit,
              child: Text(widget.user == null ? 'Create' : 'Save')),
        ],
      );

  Widget _field(String key, String label,
          {bool required = false,
          bool numeric = false,
          bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: TextFormField(
          controller: _fields[key],
          obscureText: obscure,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true, signed: true)
              : null,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (value) => value == null || value.trim().isEmpty
                  ? '$label is required'
                  : null
              : null,
        ),
      );

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final user = widget.user;
    final common = <String, dynamic>{};
    void changed(String key, dynamic oldValue) {
      final value = _fields[key]!.text.trim();
      if (user == null || value != (oldValue ?? '').toString()) {
        common[key] = value;
      }
    }

    changed('username', user?.username);
    changed('email', user?.email);
    changed('firstName', user?.firstName);
    changed('lastName', user?.lastName);
    changed('phone', user?.phone);
    if (user == null) common['password'] = _fields['password']!.text;

    final roleSpecific = <String, dynamic>{};
    if (_role == 'DRIVER') {
      final fee = double.tryParse(_fields['deliveryFee']!.text);
      if (user == null || fee != user.deliveryFee) {
        roleSpecific['deliveryFee'] = fee;
      }
    } else if (_role == 'MERCHANT') {
      if (user == null || _accountType != user.accountType?.toUpperCase()) {
        roleSpecific['accountType'] = _accountType.toLowerCase();
        if (_accountType == 'POSTPAID') {
          roleSpecific['paymentDay'] = _fields['paymentDay']!.text.trim();
        }
      }
      final prefix = _fields['orderIdPrefix']!.text.trim();
      if (user == null || prefix != (user.orderIdPrefix ?? '')) {
        roleSpecific['orderIdPrefix'] = prefix;
      }
    }

    final createPayload = user == null
        ? buildUserPayload(
            username: common['username'],
            email: common['email'],
            password: common['password'],
            firstName: common['firstName'],
            lastName: common['lastName'],
            phone: common['phone'],
            deliveryFee: _role == 'DRIVER'
                ? double.tryParse(_fields['deliveryFee']!.text)
                : null,
            accountType: _role == 'MERCHANT' ? _accountType : null,
            paymentDay: _role == 'MERCHANT' && _accountType == 'POSTPAID'
                ? _fields['paymentDay']!.text.trim()
                : null,
            orderIdPrefix: _role == 'MERCHANT'
                ? _fields['orderIdPrefix']!.text.trim()
                : null,
          )
        : common;
    Navigator.pop(
      context,
      _UserSubmission(
        _role,
        createPayload,
        roleSpecific,
        _role == 'MERCHANT' && _accountType == 'PREPAID'
            ? double.tryParse(_fields['legacyBalance']!.text)
            : null,
      ),
    );
  }
}
