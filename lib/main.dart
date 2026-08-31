import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/auth_providers.dart';

void main() {
  runApp(const ProviderScope(child: QrexApp()));
}

/// Thin wrapper that kicks off session restoration on startup.
class SessionBootstrap extends ConsumerStatefulWidget {
  final Widget child;
  const SessionBootstrap({super.key, required this.child});

  @override
  ConsumerState<SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends ConsumerState<SessionBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
