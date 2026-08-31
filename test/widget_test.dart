import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrex_mobile/app.dart';
import 'package:qrex_mobile/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('QrexApp shows splash, then routes to login when no session',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: QrexApp()),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Advance fake time past the session-restore timeout so the splash always
    // resolves (with no cached session it redirects to the login screen).
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
