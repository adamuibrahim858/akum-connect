import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akum_connet/pages/portal_webview_page.dart';

void main() {
  testWidgets('PortalWebViewPage builds cleanly without throwing on desktop', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortalWebViewPage(),
      ),
    );

    expect(find.text('AKUM Student Portal'), findsOneWidget);
    expect(find.text('Open Portal in Browser'), findsOneWidget);
  });
}
