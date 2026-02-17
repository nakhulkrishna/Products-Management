import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget test harness works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Products Catalog'))),
      ),
    );

    expect(find.text('Products Catalog'), findsOneWidget);
  });
}
