import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/core/models/app_role.dart';
import 'package:resandang/core/models/user_access.dart';
import 'package:resandang/features/auth/presentation/auth_state_notifier.dart';
import 'package:resandang/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockAuthService mockAuthService;
  late AuthStateNotifier notifier;

  setUp(() {
    mockAuthService = MockAuthService();
    notifier = AuthStateNotifier(authService: mockAuthService);
  });

  group('AuthStateNotifier', () {
    test('initial state is unauthenticated and not loading', () {
      expect(notifier.isLoading, isFalse);
      expect(notifier.errorMessage, isNull);
      expect(notifier.currentUser, isNull);
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.currentAccess.roles, isEmpty);
      expect(notifier.currentAccess.ui, AppUiShell.user);
    });

    test('initialize loads user and access if already logged in', () async {
      final mockUser = MockUser();
      when(() => mockAuthService.currentUser).thenReturn(mockUser);
      when(() => mockAuthService.fetchAccess()).thenAnswer(
        (_) async => const UserAccess(
          roles: [AppRole.donatur],
          ui: AppUiShell.user,
        ),
      );

      await notifier.initialize();

      expect(notifier.isLoading, isFalse);
      expect(notifier.currentUser, mockUser);
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.currentAccess.roles, [AppRole.donatur]);
    });

    test('signIn succeeds and updates access', () async {
      final mockUser = MockUser();
      final mockResponse = MockAuthResponse();
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockAuthService.signIn(email: 'user@test.com', password: '123'))
          .thenAnswer((_) async => mockResponse);
      when(() => mockAuthService.currentUser).thenReturn(mockUser);
      when(() => mockAuthService.fetchAccess()).thenAnswer(
        (_) async => const UserAccess(
          roles: [AppRole.donatur],
          ui: AppUiShell.user,
        ),
      );

      final success = await notifier.signIn('user@test.com', '123');

      expect(success, isTrue);
      expect(notifier.isLoading, isFalse);
      expect(notifier.currentUser, mockUser);
      expect(notifier.currentAccess.roles, [AppRole.donatur]);
      expect(notifier.errorMessage, isNull);
    });

    test('signIn sets errorMessage on failure', () async {
      when(() => mockAuthService.signIn(email: 'user@test.com', password: 'wrong'))
          .thenThrow(const AuthException('Invalid login credentials'));

      final success = await notifier.signIn('user@test.com', 'wrong');

      expect(success, isFalse);
      expect(notifier.isLoading, isFalse);
      expect(notifier.errorMessage, 'Invalid login credentials');
      expect(notifier.isAuthenticated, isFalse);
    });

    test('signOut clears user and resets access', () async {
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      await notifier.signOut();

      expect(notifier.currentUser, isNull);
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.currentAccess.roles, isEmpty);
    });
  });
}
