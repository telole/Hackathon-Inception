class AppProfile {
  final String id;
  final String displayName;
  final String? avatarPath;
  final String? area;

  const AppProfile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    this.area,
  });

  factory AppProfile.fromMap(Map<String, dynamic> map, {String? defaultId}) {
    return AppProfile(
      id: map['id']?.toString() ?? defaultId ?? '',
      displayName: map['display_name']?.toString() ?? 'Pengguna',
      avatarPath: map['avatar_path']?.toString(),
      area: map['area']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_path': avatarPath,
      'area': area,
    };
  }
}
