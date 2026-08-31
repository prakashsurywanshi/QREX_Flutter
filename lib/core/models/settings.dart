import '../utils/num_parsers.dart';

class SettingsData {
  final Map<String, dynamic> values;

  const SettingsData(this.values);

  String get projectName => _str('project_name');
  String get agencyName => _str('agency_name');
  String get tagline => _str('tagline');
  String get contactEmail => _str('contact_email');
  String get contactPhone => _str('contact_phone');
  String get address => _str('address');
  String get currency => _str('currency');
  String get timezone => _str('timezone');
  String get dateFormat => _str('date_format');
  String get primaryColor => _str('primary_color');
  String get accentColor => _str('accent_color');
  String get officeHours => _str('office_hours');
  bool get enableContactForm => _bool('enable_contact_form');
  bool get maintenanceMode => _bool('maintenance_mode');
  bool get twoFactor => _bool('two_factor');
  bool get leadAutoAssign => _bool('lead_auto_assign');
  bool get visitReminders => _bool('visit_reminders');
  bool get paymentAlerts => _bool('payment_alerts');
  bool get lowInventoryAlert => _bool('low_inventory_alert');

  String _str(String key) => '${values[key] ?? ''}';

  bool _bool(String key) {
    final v = values[key];
    if (v is bool) return v;
    var s = '$v'.toLowerCase();
    return s == 'true' || s == '1';
  }

  Map<String, dynamic> mergedWith(Map<String, dynamic> updates) {
    return {...values, ...updates};
  }

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(json.map((k, v) => MapEntry(k, v ?? '')));
  }
}

class SmtpConfig {
  final bool enabled;
  final String host;
  final int port;
  final String username;
  final String password;
  final String encryption;
  final String fromAddress;
  final String fromName;
  final String testEmail;

  const SmtpConfig({
    this.enabled = false,
    this.host = '',
    this.port = 587,
    this.username = '',
    this.password = '',
    this.encryption = 'tls',
    this.fromAddress = '',
    this.fromName = '',
    this.testEmail = '',
  });

  factory SmtpConfig.fromJson(Map<String, dynamic> json) {
    final portValue = parseInt(json['port']);
    return SmtpConfig(
      enabled: json['enabled'] == true || json['enabled'] == 1,
      host: json['host'] ?? '',
      port: portValue == 0 ? 587 : portValue,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      encryption: json['encryption'] ?? 'tls',
      fromAddress: json['from_address'] ?? '',
      fromName: json['from_name'] ?? '',
      testEmail: json['test_email'] ?? '',
    );
  }
}

class SettingsIndex {
  final SettingsData settings;
  final SmtpConfig smtp;

  const SettingsIndex({
    this.settings = const SettingsData({}),
    this.smtp = const SmtpConfig(),
  });

  factory SettingsIndex.fromJson(Map<String, dynamic> json) {
    return SettingsIndex(
      settings: SettingsData.fromJson(
          json['settings'] as Map<String, dynamic>? ?? {}),
      smtp: SmtpConfig.fromJson(json['smtp'] as Map<String, dynamic>? ?? {}),
    );
  }
}