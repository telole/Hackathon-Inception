import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/core/models/app_role.dart';
import 'package:resandang/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    authService = AuthService(client: mockSupabase);
  });

  group('AuthService', () {
    test('signUp delegates to GoTrueClient signUp with display_name metadata', () async {
      final mockResponse = MockAuthResponse();
      when(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          emailRedirectTo: 'com.resandang.resandang://auth-callback',
          data: {'display_name': 'Budi Santoso'},
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'password123',
        fullName: 'Budi Santoso',
      );

      expect(result, mockResponse);
      verify(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          emailRedirectTo: 'com.resandang.resandang://auth-callback',
          data: {'display_name': 'Budi Santoso'},
        ),
      ).called(1);
    });

    test('signUp prefers displayName over fullName when both provided', () async {
      final mockResponse = MockAuthResponse();
      when(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          emailRedirectTo: 'com.resandang.resandang://auth-callback',
          data: {'display_name': 'Budi Display'},
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'password123',
        fullName: 'Budi Santoso',
        displayName: 'Budi Display',
      );

      expect(result, mockResponse);
      verify(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          emailRedirectTo: 'com.resandang.resandang://auth-callback',
          data: {'display_name': 'Budi Display'},
        ),
      ).called(1);
    });

    test('signIn delegates to GoTrueClient signInWithPassword', () async {
      final mockResponse = MockAuthResponse();
      when(
        () => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await authService.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, mockResponse);
      verify(
        () => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('signOut delegates to GoTrueClient signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('fetchAccess calls my_access RPC and returns parsed UserAccess', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<dynamic>(
        Future.value({
          'roles': ['donatur', 'relawan'],
          'ui': 'user',
        }),
      );
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      when(() => mockSupabase.rpc('my_access')).thenAnswer((_) => fakeBuilder);

      final access = await authService.fetchAccess();

      expect(access.ui, AppUiShell.user);
      expect(access.roles, [AppRole.donatur, AppRole.relawan]);
      verify(() => mockSupabase.rpc('my_access')).called(1);
    });

    test('fetchAccess returns empty UserAccess when user is not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final access = await authService.fetchAccess();

      expect(access.ui, AppUiShell.user);
      expect(access.roles, isEmpty);
      verifyNever(() => mockSupabase.rpc('my_access'));
    });

    test('fetchAccess rethrows error when RPC fails rather than hiding it as empty access', () async {
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      when(() => mockSupabase.rpc('my_access')).thenThrow(
        const PostgrestException(message: 'Connection failed', code: '500'),
      );

      expect(() => authService.fetchAccess(), throwsA(isA<PostgrestException>()));
    });
  });
}
