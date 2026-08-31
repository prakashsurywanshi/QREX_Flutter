/// Parses and exposes the backend `can` map from /auth/me.
///
/// Shape (per module):
/// {
///   "view": bool, "create": bool, "edit": bool,
///   "delete": bool, "export": bool, "approve": bool,
///   "fields": {"fieldName": bool, ...}
/// }
class ModulePermissions {
  final bool view;
  final bool create;
  final bool edit;
  final bool delete;
  final bool export;
  final bool approve;
  final Map<String, bool> fields;

  const ModulePermissions({
    required this.view,
    required this.create,
    required this.edit,
    required this.delete,
    required this.export,
    required this.approve,
    required this.fields,
  });

  factory ModulePermissions.fromJson(Map<String, dynamic> json) {
    final fieldsRaw = json['fields'];
    // The backend emits an empty array (`[]`) for modules that have no
    // field-level permissions and an object (`{}`) otherwise. Accept both.
    final Map<String, dynamic> fieldsMap = switch (fieldsRaw) {
      Map<String, dynamic> m => m,
      Map m => m.cast<String, dynamic>(),
      _ => const {},
    };
    return ModulePermissions(
      view: json['view'] == true,
      create: json['create'] == true,
      edit: json['edit'] == true,
      delete: json['delete'] == true,
      export: json['export'] == true,
      approve: json['approve'] == true,
      fields: fieldsMap.map((k, v) => MapEntry(k, v == true)),
    );
  }

  bool canEditField(String field) => fields[field] == true;

  Map<String, dynamic> toJson() => {
        'view': view,
        'create': create,
        'edit': edit,
        'delete': delete,
        'export': export,
        'approve': approve,
        'fields': fields,
      };
}

/// Full permissions map keyed by module name.
class PermissionMap {
  final Map<String, ModulePermissions> modules;

  PermissionMap({required this.modules});

  factory PermissionMap.fromJson(Map<String, dynamic> json) {
    return PermissionMap(
      modules: json.map((key, value) =>
          MapEntry(key, ModulePermissions.fromJson(value))),
    );
  }

  ModulePermissions? operator [](String module) => modules[module];

  ModulePermissions moduleOf(String name) => modules[name] ?? _none;

  bool canView(String mod) => moduleOf(mod).view;
  bool canCreate(String mod) => moduleOf(mod).create;
  bool canEdit(String mod) => moduleOf(mod).edit;
  bool canDelete(String mod) => moduleOf(mod).delete;
  bool canExport(String mod) => moduleOf(mod).export;
  bool canApprove(String mod) => moduleOf(mod).approve;
  bool canEditField(String mod, String field) =>
      moduleOf(mod).canEditField(field);

  Map<String, dynamic> toJson() =>
      modules.map((k, v) => MapEntry(k, v.toJson()));

  static const ModulePermissions _none = ModulePermissions(
    view: false,
    create: false,
    edit: false,
    delete: false,
    export: false,
    approve: false,
    fields: {},
  );
}
