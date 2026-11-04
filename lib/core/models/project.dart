class Project {
  Project({required this.id, this.name, this.location, this.status, this.unitsCount});
  final int id;
  final String? name;
  final String? location;
  final String? status;
  final int? unitsCount;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      status: json['status'],
      unitsCount: json['units_count'],
    );
  }
}
