import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:godelivery_lb_app/models/communication_status.dart';
import 'package:godelivery_lb_app/widgets/communication_status_card.dart';

void main() {
  test('status model reads safe fields and ignores any unexpected credentials',
      () {
    final status = CommunicationStatus.fromJson({
      'provider': 'Twilio',
      'whatsapp': 'Configured',
      'sms': 'Disabled',
      'dryRun': false,
      'configured': true,
      'customerAutomation': false,
      'authToken': 'must-not-be-modeled',
      'apiSecret': 'must-not-be-modeled',
    });

    expect(status.provider, 'Twilio');
    expect(status.whatsapp, 'Configured');
    expect(status.sms, 'Disabled');
    expect(status.customerAutomation, isFalse);
    expect(status.toString(), isNot(contains('must-not-be-modeled')));
  });

  testWidgets('Admin status card displays configuration state without secrets',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommunicationStatusCard(
          loadStatus: () async => {
            'success': true,
            'data': {
              'provider': 'Twilio',
              'whatsapp': 'Configured',
              'sms': 'Disabled',
              'dryRun': false,
              'configured': true,
              'customerAutomation': false,
              'authToken': 'never-render-this-value',
            },
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Transactional communications'), findsOneWidget);
    expect(find.text('Configured'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.textContaining('never-render-this-value'), findsNothing);
    expect(find.textContaining('health is not checked'), findsOneWidget);
  });
}
