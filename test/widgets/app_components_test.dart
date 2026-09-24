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
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(child: OrderStatusBadge(status: 'PICKED_UP')),
          ),
        ),
      );

      expect(find.text('Picked up'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(OrderStatusBadge)).label,
        contains('Order status: Picked up'),
      );
      semantics.dispose();
    });

    testWidgets('uses theme contrast for dark collected and unknown states',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Column(
              children: [
                OrderStatusBadge(status: 'COLLECTED'),
                OrderStatusBadge(status: 'UNEXPECTED_STATUS'),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(OrderStatusBadge).first);
      final expectedColor = Theme.of(context).colorScheme.onSurfaceVariant;
      final labels = tester.widgetList<Text>(find.byType(Text)).where((text) =>
          text.data == 'Collected' || text.data == 'UNEXPECTED_STATUS');

      expect(labels, hasLength(2));
      expect(
          labels.every((label) => label.style?.color == expectedColor), isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('state widgets', () {
    testWidgets('render loading, empty, and error states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AppLoadingState(message: 'Loading jobs')),
        ),
      );
      expect(find.text('Loading jobs'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              title: 'No jobs',
              message: 'New jobs will appear here.',
            ),
          ),
        ),
      );
      expect(find.text('No jobs'), findsOneWidget);

      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppErrorState(
              message: 'Could not load jobs.',
              onRetry: () async => retries++,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('state_retry_button')));
      await tester.pump();
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
