import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(leading: Icon(Icons.palette), title: Text('Branding'), subtitle: Text('App name, logo, colors')),
          ListTile(leading: Icon(Icons.map), title: Text('Maps'), subtitle: Text('Google/Mapbox/OpenStreetMap')),
          ListTile(leading: Icon(Icons.chat), title: Text('WhatsApp'), subtitle: Text('Meta Cloud API')),
          ListTile(leading: Icon(Icons.notifications), title: Text('Notifications'), subtitle: Text('FCM')),
        ],
      ),
    );
  }
}
