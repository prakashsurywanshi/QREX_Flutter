import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhatsAppScreen extends ConsumerWidget {
  const WhatsAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp')),
      body: const Center(child: Text('WhatsApp Integration')),
    );
  }
}
