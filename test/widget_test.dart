import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:godelivery_lb_app/main.dart';

void main() {
  testWidgets('shows the public marketplace when logged out', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();

    expect(find.text('GoDelivery'), findsWidgets);
    expect(find.byTooltip('Login'), findsOneWidget);
  });
}
