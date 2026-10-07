import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/pages/start_page.dart';

void main() {
  testWidgets('shows start screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp(child: StartPage()));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(InkWell), findsNWidgets(2));
  });
}

class TestApp extends StatelessWidget {
  final Widget child;

  const TestApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
