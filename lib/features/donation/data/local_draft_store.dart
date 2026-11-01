import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One device-local draft per account/form; never shared between sessions.
class LocalDraftStore {
  LocalDraftStore(this.preferences, this.userId, this.editId);
  final SharedPreferences preferences;
  final String userId;
  final String? editId;
  String get key => 'pk.donation.draft.$userId.${editId ?? 'new'}';
  Map<String, dynamic>? read() {
    final raw = preferences.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> value) async {
    await preferences.setString(key, jsonEncode(value));
  }

  Future<void> clear() async {
    await preferences.remove(key);
  }

  static Future<void> clearAccount(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (k) => k.startsWith('pk.donation.draft.$userId.'),
    )) {
      await preferences.remove(key);
    }
  }
}
