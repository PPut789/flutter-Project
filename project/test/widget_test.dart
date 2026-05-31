import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:project/main.dart';

void main() {
  testWidgets('shows start screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Get Start'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
