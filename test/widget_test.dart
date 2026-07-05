import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:PiliPlus/common/widgets/custom_toast.dart';

void main() {
  testWidgets('LoadingWidget renders progress and message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: LoadingWidget(msg: 'Loading test'),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading test'), findsOneWidget);
  });
}
