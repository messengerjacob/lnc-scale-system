import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scaleflow_app/main.dart';

void main() {
  testWidgets('ScaleFlowApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScaleFlowApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
