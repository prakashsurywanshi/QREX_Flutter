import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentPlansScreen extends ConsumerWidget {
  const PaymentPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Plans')),
      body: const Center(child: Text('Payment Plans - Coming Soon')),
    );
  }
}
