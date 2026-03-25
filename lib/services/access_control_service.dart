class AccessControlService {
  static const String actionCreate = 'create';
  static const String actionRead   = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static const List<String> availableRoles = ['Ketua', 'Anggota', 'Asisten'];

  static final Map<String, List<String>> _rolePermissions = {
    'Ketua'   : [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota' : [actionCreate, actionRead],
    'Asisten' : [actionRead, actionUpdate],
  };


  static bool canPerform(
    String role,
    String action, {
    bool isOwner = false,
  }) {
    if (action == actionUpdate || action == actionDelete) {
      return isOwner;
    }

    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }
}