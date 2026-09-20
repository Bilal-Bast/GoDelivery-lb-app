import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:godelivery_lb_app/main.dart';
import 'package:godelivery_lb_app/providers/providers.dart';

void main() {
  testWidgets('shows the public marketplace when logged out', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider();
    await authProvider.restoreSession(refreshAccessToken: false);

    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.text('GoDelivery'), findsWidgets);
    expect(find.byTooltip('Login'), findsOneWidget);
  });
}
