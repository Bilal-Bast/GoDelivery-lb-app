import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';
import '../../widgets/godelivery_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PasswordShell(
        title: 'Reset your password',
        subtitle: 'We will send a one-hour reset link if the account exists.',
        child: Consumer<PasswordFlowProvider>(builder: (context, provider, _) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('forgot_email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.md),
                if (provider.error != null)
                  Text(provider.error!,
                      style: TextStyle(color: context.colors.error)),
                if (provider.message != null)
                  Text(provider.message!,
                      style: TextStyle(color: context.colors.primary)),
                FilledButton(
                  key: const Key('forgot_submit'),
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.requestReset(_email.text),
                  child:
                      Text(provider.isLoading ? 'Sending…' : 'Send reset link'),
                ),
              ]);
        }),
      );
}

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PasswordShell(
        title: 'Choose a new password',
        subtitle:
            'Use at least 8 characters with upper/lowercase, a number and symbol.',
        child: Consumer<PasswordFlowProvider>(builder: (context, provider, _) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('reset_password'),
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('reset_confirm'),
                  controller: _confirm,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_localError != null || provider.error != null)
                  Text(_localError ?? provider.error!,
                      style: TextStyle(color: context.colors.error)),
                if (provider.message != null) Text(provider.message!),
                FilledButton(
                  key: const Key('reset_submit'),
                  onPressed:
                      provider.isLoading ? null : () => _submit(provider),
                  child: Text(
                      provider.isLoading ? 'Updating…' : 'Update password'),
                ),
              ]);
        }),
      );

  Future<void> _submit(PasswordFlowProvider provider) async {
    setState(() => _localError = null);
    if (widget.token.isEmpty) {
      setState(() => _localError = 'Reset token is missing.');
      return;
    }
    if (_password.text.length < 8 || _password.text != _confirm.text) {
      setState(() =>
          _localError = 'Passwords must match and meet the requirements.');
      return;
    }
    final success = await provider.resetPassword(widget.token, _password.text);
    _password.clear();
    _confirm.clear();
    if (success && mounted) context.go('/login');
  }
}

class _PasswordShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _PasswordShell(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: AppSurfaceCard(
                  emphasized: true,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: GoDeliveryLogo(height: 40)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(title, style: context.textStyles.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle),
                        const SizedBox(height: AppSpacing.lg),
                        child,
                        TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Back to sign in')),
                      ]),
                ),
              ),
            ),
          ),
        ),
      );
}
