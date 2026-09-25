import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../providers/providers.dart';
import '../../widgets/app_components.dart';
import '../../widgets/godelivery_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: LoginForm(
                      formKey: _formKey,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onLogin: _login,
                      showLogo: true,
                    ),
                  ),
                ),
              );
            }
            return Row(
              children: [
                const Expanded(flex: 5, child: LoginBrandPanel()),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: LoginForm(
                          formKey: _formKey,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onLogin: _login,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.navyLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Stack(
          children: [
            const Positioned(
                right: -60, top: -60, child: BrandOrb(size: 260, opacity: .07)),
            const Positioned(
                left: -40,
                bottom: -50,
                child: BrandOrb(size: 220, opacity: .1)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoDeliveryLogo(height: 44, withSurface: true),
                  const Spacer(),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Delivery operations,\nmade clear.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: const Text(
                      'Manage orders, drivers, merchants and settlements across Lebanon from one connected workspace.',
                      style: TextStyle(
                          color: AppColors.onDarkMuted,
                          fontSize: 16,
                          height: 1.55),
                    ),
                  ),
                  const Spacer(),
                  const Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    children: [
                      LoginFeature(
                          icon: Icons.route_rounded, label: 'Live workflows'),
                      LoginFeature(
                          icon: Icons.shield_outlined, label: 'Role-secured'),
                      LoginFeature(
                          icon: Icons.devices_rounded, label: 'Every device'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const BrandOrb({super.key, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class LoginFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const LoginFeature({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.onDark),
        const SizedBox(width: AppSpacing.xs),
        Text(label,
            style: const TextStyle(
                color: AppColors.onDark, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onLogin;
  final bool showLogo;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showLogo) ...[
                const Align(
                    alignment: Alignment.centerLeft,
                    child: GoDeliveryLogo(height: 44)),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text('Welcome back', style: context.textStyles.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to your GoDelivery workspace.',
                style: context.textStyles.bodyLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                key: const Key('login_username_field'),
                controller: usernameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Username is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('login_password_field'),
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => onLogin(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip:
                        obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: onTogglePassword,
                    icon: Icon(obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Password is required'
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ),
              if (auth.error != null) ...[
                LoginError(message: auth.error!),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton(
                key: const Key('login_submit_button'),
                onPressed: auth.isLoading ? null : () => onLogin(),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Continue browsing'),
              ),
              TextButton.icon(
                onPressed: () => context.go('/track'),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Track an order'),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('New to GoDelivery?',
                      style: context.textStyles.bodyMedium),
                  TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create an account')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class LoginError extends StatelessWidget {
  final String message;

  const LoginError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.red.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
                child: Text(message,
                    style: context.textStyles.bodySmall
                        ?.copyWith(color: AppColors.red))),
          ],
        ),
      ),
    );
  }
}
