import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_lb_app/core/theme/app_theme.dart';
import 'package:godelivery_lb_app/widgets/app_components.dart';

void main() {
  group('$AppResponsiveGrid', () {
    testWidgets('uses one column in compact constraints', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppResponsiveGrid(
              minItemWidth: 220,
              children: [
                SizedBox(key: Key('grid_item_one')),
                SizedBox(key: Key('grid_item_two')),
              ],
            ),
          ),
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expands to four columns on a wide surface', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppResponsiveGrid(
              minItemWidth: 220,
              children: [
                SizedBox(),
                SizedBox(),
                SizedBox(),
                SizedBox(),
              ],
            ),
          ),
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
      expect(tester.takeException(), isNull);
    });
  });

  group('$AppPageHeader', () {
    testWidgets('keeps actions usable without overflow on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppPageHeader(
              title: 'Delivery operations',
              subtitle: 'A long supporting description for a compact window.',
              actions: [
                OutlinedButton(onPressed: () {}, child: const Text('Refresh')),
                FilledButton(onPressed: () {}, child: const Text('New order')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Delivery operations'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('New order'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('$OrderStatusBadge', () {
    testWidgets('presents a readable semantic delivery status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(child: OrderStatusBadge(status: 'PICKED_UP')),
          ),
        ),
      );

      expect(find.text('Picked up'), findsOneWidget);
      expect(find.bySemanticsLabel('Order status: Picked up'), findsOneWidget);
    });
  });
}
