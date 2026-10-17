import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:godelivery_lb_app/models/order.dart';
import 'package:godelivery_lb_app/services/communication_contact_service.dart';
import 'package:godelivery_lb_app/screens/orders/orders_screens.dart';
import 'package:godelivery_lb_app/widgets/communication_contact_actions.dart';

Order _order({String phone = '+961 70 123 456'}) => Order(
      id: 'A/B 12',
      merchantId: 'shop',
      customerFirstName: 'Nadia',
      customerPhone: phone,
      district: 'Beirut',
      city: 'Beirut',
      total: 18,
      deliveryCharge: 3,
      status: 'DELIVERED',
      createdAt: DateTime(2026),
      statusUpdatedAt: DateTime(2026),
    );

void main() {
  testWidgets('order detail exposes contact actions only to Admin and Driver',
      (tester) async {
    Widget detail(String role) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderDetailContent(
                order: _order(),
                role: role,
                showHeaderAction: false,
                updating: false,
                onAction: (_) {},
              ),
            ),
          ),
        );

    await tester.pumpWidget(detail('admin'));
    expect(find.byKey(const Key('contact_customer_whatsapp')), findsOneWidget);
    await tester.pumpWidget(detail('driver'));
    expect(find.byKey(const Key('contact_customer_whatsapp')), findsOneWidget);
    await tester.pumpWidget(detail('merchant'));
    expect(find.byKey(const Key('contact_customer_whatsapp')), findsNothing);
    await tester.pumpWidget(detail(''));
    expect(find.byKey(const Key('contact_customer_whatsapp')), findsNothing);
  });

  testWidgets('preview can be cancelled without launching WhatsApp',
      (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommunicationContactActions(
          order: _order(),
          loadPreview: (id) async => {
            'success': true,
            'available': true,
            'phone': '+96170123456',
            'maskedPhone': '+961••••••456',
            'text': 'Hello Nadia, track order A/B 12.',
          },
          contactService: CommunicationContactService(
            defaultCountryCode: '961',
            launch: (Uri uri, LaunchMode mode) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('contact_customer_whatsapp')));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp Customer'), findsOneWidget);
    expect(find.text('Recipient: +961••••••456'), findsOneWidget);
    expect(find.textContaining('press Send'), findsOneWidget);
    await tester.tap(find.byKey(const Key('whatsapp_preview_cancel')));
    await tester.pumpAndSettle();
    expect(launched, isEmpty);
  });

  testWidgets('opening WhatsApp uses preview text and remains a manual action',
      (tester) async {
    final launched = <Uri>[];
    final previewIds = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommunicationContactActions(
          order: _order(),
          loadPreview: (id) async {
            previewIds.add(id);
            return {
              'success': true,
              'available': true,
              'phone': '+96170123456',
              'maskedPhone': '+961••••••456',
              'text':
                  'Hello Nadia. Track: https://example.test/track?id=A%2FB+12',
            };
          },
          contactService: CommunicationContactService(
            defaultCountryCode: '961',
            launch: (Uri uri, LaunchMode mode) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('contact_customer_whatsapp')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('whatsapp_preview_open')));
    await tester.pumpAndSettle();
    expect(previewIds, ['A/B 12']);
    expect(launched, hasLength(1));
    expect(
        launched.single.queryParameters['text'], contains('track?id=A%2FB+12'));
    expect(find.textContaining('Press Send there'), findsOneWidget);
  });

  testWidgets('missing customer phone disables contact controls',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommunicationContactActions(
          order: _order(phone: ''),
          loadPreview: (id) async => throw StateError('must not load'),
          contactService: CommunicationContactService(
            launch: (Uri uri, LaunchMode mode) async => true,
          ),
        ),
      ),
    ));
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('contact_customer_call')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('contact_customer_whatsapp')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Customer phone is not available.'), findsOneWidget);
  });

  testWidgets(
      'contact controls and preview fit phone, tablet, and desktop widths',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in [
      const Size(320, 720),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommunicationContactActions(
              order: _order(),
              loadPreview: (id) async => {
                'success': true,
                'available': true,
                'phone': '+96170123456',
                'maskedPhone': '+961••••••456',
                'text': 'Hello Nadia, track order A/B 12.',
              },
              contactService: CommunicationContactService(
                defaultCountryCode: '961',
                launch: (Uri uri, LaunchMode mode) async => true,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('contact_customer_call')), findsOneWidget);
      expect(
          find.byKey(const Key('contact_customer_whatsapp')), findsOneWidget);

      await tester.tap(find.byKey(const Key('contact_customer_whatsapp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('whatsapp_preview_open')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('whatsapp_preview_cancel')));
      await tester.pumpAndSettle();
    }
  });
}
