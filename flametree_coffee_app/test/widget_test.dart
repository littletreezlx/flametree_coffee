// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flametree_coffee_app/main.dart';

void main() {
  testWidgets('App launches test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlametreeCoffeeApp());

    // Verify that the app launches with the home screen
    expect(find.text('火树咖啡厅'), findsOneWidget);
    expect(find.text('家庭点餐系统'), findsOneWidget);
    expect(find.text('请选择家庭成员'), findsOneWidget);
  });
}
