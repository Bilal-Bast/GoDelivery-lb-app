import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ContactUriLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

enum ContactLaunchResult { launched, invalidPhone, unavailable }

class CommunicationContactService {
  final ContactUriLauncher _launch;
  final String defaultCountryCode;

  CommunicationContactService({
    ContactUriLauncher? launch,
    this.defaultCountryCode = const String.fromEnvironment(
      'DEFAULT_PHONE_COUNTRY_CODE',
    ),
  }) : _launch = launch ?? _launchUrl;

  static Future<bool> _launchUrl(Uri uri, LaunchMode mode) =>
      launchUrl(uri, mode: mode);

  String? normalizePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final input = value.trim();
    final international = input.startsWith('+') || input.startsWith('00');
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (input.startsWith('00')) digits = digits.substring(2);
    if (digits.isEmpty) return null;

    final countryCode = defaultCountryCode.replaceAll(RegExp(r'\D'), '');
    if (!international) {
      if (countryCode.isEmpty) return null;
      if (digits.startsWith(countryCode)) {
        final national = digits.substring(countryCode.length).replaceFirst(
              RegExp(r'^0'),
              '',
            );
        digits = '$countryCode$national';
      } else {
        digits = '$countryCode${digits.replaceFirst(RegExp(r'^0'), '')}';
      }
    } else if (countryCode.isNotEmpty && digits.startsWith(countryCode)) {
      final national = digits.substring(countryCode.length).replaceFirst(
            RegExp(r'^0'),
            '',
          );
      digits = '$countryCode$national';
    }

    if (digits.length < 8 || digits.length > 15 || digits.startsWith('0')) {
      return null;
    }
    return '+$digits';
  }

  String maskPhoneNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return '***';
    final visiblePrefix = digits.substring(0, digits.length > 8 ? 3 : 2);
    return '+$visiblePrefix••••••${digits.substring(digits.length - 3)}';
  }

  Uri? buildWhatsAppUri({required String phone, required String message}) {
    final normalized = normalizePhoneNumber(phone);
    if (normalized == null || message.trim().isEmpty) return null;
    final digits = normalized.substring(1);
    return Uri.https('wa.me', '/$digits', {'text': message});
  }

  Uri? buildTelephoneUri(String phone) {
    final normalized = normalizePhoneNumber(phone);
    if (normalized == null) return null;
    return Uri(scheme: 'tel', path: normalized);
  }

  Future<ContactLaunchResult> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final uri = buildWhatsAppUri(phone: phone, message: message);
    if (uri == null) return ContactLaunchResult.invalidPhone;
    try {
      const mode =
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
      return await _launch(uri, mode)
          ? ContactLaunchResult.launched
          : ContactLaunchResult.unavailable;
    } catch (_) {
      return ContactLaunchResult.unavailable;
    }
  }

  Future<ContactLaunchResult> callCustomer(String phone) async {
    final uri = buildTelephoneUri(phone);
    if (uri == null) return ContactLaunchResult.invalidPhone;
    try {
      return await _launch(uri, LaunchMode.externalApplication)
          ? ContactLaunchResult.launched
          : ContactLaunchResult.unavailable;
    } catch (_) {
      return ContactLaunchResult.unavailable;
    }
  }
}
