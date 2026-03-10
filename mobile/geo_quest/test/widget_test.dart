import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_quest/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoQuestApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
