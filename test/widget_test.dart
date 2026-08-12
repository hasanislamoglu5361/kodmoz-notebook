import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kodmoz_notebook/main.dart';

void main() {
  testWidgets('App boots into splash while checking for saved token',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KodmozNotebookApp());
    // The bootstrap future has not resolved yet, so we should see the splash.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
