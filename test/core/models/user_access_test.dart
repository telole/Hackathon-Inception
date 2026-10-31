import 'package:flutter_test/flutter_test.dart';
import 'package:resandang/core/models/app_role.dart';
import 'package:resandang/core/models/user_access.dart';

void main() {
  group('UserAccess', () {
    test('parses default new user response from my_access RPC', () {
      final json = {
        'roles': ['donatur'],
        'ui': 'user',
      };

      final access = UserAccess.fromJson(json);

      expect(access.ui, AppUiShell.user);
      expect(access.roles, [AppRole.donatur]);
      expect(access.isDonatur, isTrue);
      expect(access.isRelawan, isFalse);
      expect(access.isMitra, isFalse);
      expect(access.isAdmin, isFalse);
    });

    test('parses multi-role user (e.g. donatur + relawan) correctly', () {
      final json = {
        'roles': ['donatur', 'relawan'],
        'ui': 'user',
      };

      final access = UserAccess.fromJson(json);

      expect(access.ui, AppUiShell.user);
      expect(access.roles, containsAll([AppRole.donatur, AppRole.relawan]));
      expect(access.isDonatur, isTrue);
      expect(access.isRelawan, isTrue);
      expect(access.isMitra, isFalse);
      expect(access.isAdmin, isFalse);
    });

    test('parses admin user response correctly', () {
      final json = {
        'roles': ['donatur', 'admin'],
        'ui': 'admin',
      };

      final access = UserAccess.fromJson(json);

      expect(access.ui, AppUiShell.admin);
      expect(access.isAdmin, isTrue);
    });

    test('handles empty or malformed role payload safely with empty roles', () {
      final json = {
        'roles': null,
        'ui': 'user',
      };

      final access = UserAccess.fromJson(json);

      expect(access.ui, AppUiShell.user);
      expect(access.roles, isEmpty);
      expect(access.isDonatur, isFalse);
      expect(access.isAdmin, isFalse);
    });
  });
}
