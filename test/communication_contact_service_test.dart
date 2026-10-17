import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:godelivery_lb_app/services/communication_contact_service.dart';

void main() {
  test('normalizes formatted international and configured local phones', () {
    final service = CommunicationContactService(defaultCountryCode: '961');
    expect(service.normalizePhoneNumber('+961 (70) 123-456'), '+96170123456');
    expect(service.normalizePhoneNumber('00961 70 123 456'), '+96170123456');
    expect(service.normalizePhoneNumber('03 123456'), '+9613123456');
    expect(
      CommunicationContactService().normalizePhoneNumber('03 123456'),
      isNull,
    );
    expect(service.normalizePhoneNumber('invalid'), isNull);
    expect(service.normalizePhoneNumber('+123'), isNull);
  });

  test('WhatsApp URI encodes Arabic, punctuation, order IDs and tracking URL',
      () {
    final service = CommunicationContactService(defaultCountryCode: '961');
    const message =
        'أهلًا! Order A/B 12: https://www.godelivery-lb.com/track?id=A%2FB+12';
    final uri = service.buildWhatsAppUri(
      phone: '+961 70 123 456',
      message: message,
    );
    expect(uri?.host, 'wa.me');
    expect(uri?.path, '/96170123456');
    expect(uri?.queryParameters['text'], message);
  });

  test('contact service reports unavailable launchers without throwing',
      () async {
    final service = CommunicationContactService(
      defaultCountryCode: '961',
      launch: (Uri uri, LaunchMode mode) async => false,
    );
    expect(
      await service.openWhatsApp(phone: '+96170123456', message: 'Hello'),
      ContactLaunchResult.unavailable,
    );
    expect(
      await service.callCustomer('+96170123456'),
      ContactLaunchResult.unavailable,
    );
    expect(
      await service.callCustomer('not a phone'),
      ContactLaunchResult.invalidPhone,
    );
  });
}
