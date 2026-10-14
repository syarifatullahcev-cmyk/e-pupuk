import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epupuk_mobile/main.dart';

void main() {
  testWidgets('EPupukApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EPupukApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
