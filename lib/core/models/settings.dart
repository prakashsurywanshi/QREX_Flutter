class AppSettings {
  AppSettings({this.data = const {}});
  final Map<String, dynamic> data;
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(data: json);
  }
}
