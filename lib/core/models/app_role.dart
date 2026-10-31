enum AppRole {
  donatur,
  relawan,
  mitra,
  admin;

  static AppRole? fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'donatur':
        return AppRole.donatur;
      case 'relawan':
        return AppRole.relawan;
      case 'mitra':
        return AppRole.mitra;
      case 'admin':
        return AppRole.admin;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case AppRole.donatur:
        return 'Donatur';
      case AppRole.relawan:
        return 'Sahabat Sandang (Relawan)';
      case AppRole.mitra:
        return 'Mitra Penerima / Posko';
      case AppRole.admin:
        return 'Administrator';
    }
  }
}

enum AppUiShell {
  user,
  admin;

  static AppUiShell fromString(String? value) {
    if (value?.toLowerCase().trim() == 'admin') {
      return AppUiShell.admin;
    }
    return AppUiShell.user;
  }
}