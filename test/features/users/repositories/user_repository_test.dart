import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:offline_first_app/src/common/patterns/result_pattern.dart';
import 'package:offline_first_app/src/features/users/models/user_model.dart';
import 'package:offline_first_app/src/features/users/repositories/user_repository.dart';

import '../user_mocks.mocks.dart';

void main() {
  group('UserRepository Test', () {
    late MockHttpService mockHttpService;
    late MockConnectionService mockConnectionService;
    late MockUserLocalService mockUserLocalService;
    late UserRepository repository;

    setUp(() {
      mockHttpService = MockHttpService();
      mockConnectionService = MockConnectionService();
      mockUserLocalService = MockUserLocalService();
      repository = UserRepositoryImpl(
        httpService: mockHttpService,
        connectionService: mockConnectionService,
        userLocalService: mockUserLocalService,
      );
    });

    // ---------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------

    final tUserJson = [
      {
        'id': 1,
        'name': 'Leanne Graham',
        'username': 'Bret',
        'email': 'Sincere@april.biz',
        'phone': '1-770-736-0860',
        'website': 'hildegard.org',
        'address': null,
        'company': null,
      },
    ];

    final tRemoteUsers = tUserJson.map((e) => UserModel.fromJson(e)).toList();

    final tLocalUsers = [
      UserModel(id: 99, name: 'Cached User', username: 'cache'),
    ];

    // Convenience stubs reused across tests.
    void stubConnected() {
      when(mockConnectionService.checkConnection()).thenAnswer((_) async {
        return;
      });
      when(mockConnectionService.isConnected).thenReturn(true);
    }

    void stubDisconnected() {
      when(mockConnectionService.checkConnection()).thenAnswer((_) async {
        return;
      });
      when(mockConnectionService.isConnected).thenReturn(false);
    }

    void stubLocalEmpty() {
      when(
        mockUserLocalService.getUsers(),
      ).thenAnswer((_) async => <UserModel>[]);
    }

    void stubLocalUsers() {
      when(
        mockUserLocalService.getUsers(),
      ).thenAnswer((_) async => tLocalUsers);
    }

    void stubHttp200() {
      when(mockHttpService.getData(path: anyNamed('path'))).thenAnswer(
        (_) async => (statusCode: 200, data: tUserJson, error: null),
      );
    }

    // ---------------------------------------------------------------------------
    // findAllUsers — online path
    // ---------------------------------------------------------------------------

    group('findAllUsers — online', () {
      test('should return SuccessResult with remote users '
          'when connected and API returns 200', () async {
        // arrange
        stubLocalEmpty();
        stubConnected();
        stubHttp200();
        when(mockUserLocalService.clearUsers()).thenAnswer((_) async {
          return;
        });
        when(mockUserLocalService.saveUsers(any)).thenAnswer((_) async {
          return;
        });

        // act
        final result = await repository.findAllUsers();

        // assert
        expect(result, isA<SuccessResult<List<UserModel>, Exception>>());
        final users =
            (result as SuccessResult<List<UserModel>, Exception>).value;
        expect(users.length, equals(tRemoteUsers.length));
        expect(users.first.name, equals(tRemoteUsers.first.name));
      });

      test(
        'should clear local cache and save remote users after a 200 response',
        () async {
          // arrange
          stubLocalEmpty();
          stubConnected();
          stubHttp200();
          when(mockUserLocalService.clearUsers()).thenAnswer((_) async {
            return;
          });
          when(mockUserLocalService.saveUsers(any)).thenAnswer((_) async {
            return;
          });

          // act
          await repository.findAllUsers();

          // assert — clear must happen before save
          verifyInOrder([
            mockUserLocalService.clearUsers(),
            mockUserLocalService.saveUsers(any),
          ]);
        },
      );

      test(
        'should return ErrorResult when connected but API returns non-200',
        () async {
          // arrange
          stubLocalEmpty();
          stubConnected();
          when(mockHttpService.getData(path: anyNamed('path'))).thenAnswer(
            (_) async =>
                (statusCode: 500, data: null, error: 'Internal Server Error'),
          );

          // act
          final result = await repository.findAllUsers();

          // assert
          expect(result, isA<ErrorResult<List<UserModel>, Exception>>());
          final error =
              (result as ErrorResult<List<UserModel>, Exception>).error;
          expect(error.toString(), contains('Failed to fetch users: 500'));
        },
      );

      test(
        'should return ErrorResult when connected but API returns 200 with null data',
        () async {
          // arrange
          stubLocalEmpty();
          stubConnected();
          when(
            mockHttpService.getData(path: anyNamed('path')),
          ).thenAnswer((_) async => (statusCode: 200, data: null, error: null));

          // act
          final result = await repository.findAllUsers();

          // assert
          expect(result, isA<ErrorResult<List<UserModel>, Exception>>());
        },
      );
    });

    // ---------------------------------------------------------------------------
    // findAllUsers — offline path
    // ---------------------------------------------------------------------------

    group('findAllUsers — offline', () {
      test(
        'should return ErrorResult when disconnected and local cache is empty',
        () async {
          // arrange
          stubLocalEmpty();
          stubDisconnected();

          // act
          final result = await repository.findAllUsers();

          // assert
          expect(result, isA<ErrorResult<List<UserModel>, Exception>>());
          final error =
              (result as ErrorResult<List<UserModel>, Exception>).error;
          expect(error.toString(), contains('Device not connected.'));
          verifyNever(mockHttpService.getData(path: anyNamed('path')));
        },
      );

      test('should return SuccessResult with cached users '
          'when disconnected but local cache is not empty', () async {
        // arrange
        stubLocalUsers();
        stubDisconnected();

        // act
        final result = await repository.findAllUsers();

        // assert
        expect(result, isA<SuccessResult<List<UserModel>, Exception>>());
        final users =
            (result as SuccessResult<List<UserModel>, Exception>).value;
        expect(users.length, equals(tLocalUsers.length));
        expect(users.first.name, equals(tLocalUsers.first.name));
        verifyNever(mockHttpService.getData(path: anyNamed('path')));
      });

      test(
        'should not call saveUsers or clearUsers when returning cached users',
        () async {
          // arrange
          stubLocalUsers();
          stubDisconnected();

          // act
          await repository.findAllUsers();

          // assert
          verifyNever(mockUserLocalService.clearUsers());
          verifyNever(mockUserLocalService.saveUsers(any));
        },
      );
    });

    // ---------------------------------------------------------------------------
    // findAllUsers — exception / catch fallback path
    // ---------------------------------------------------------------------------

    group('findAllUsers — exception fallback', () {
      test('should return SuccessResult with cached users '
          'when an exception is thrown and local cache is not empty', () async {
        // arrange — first getUsers call (before try block fails) returns empty,
        // exception is thrown, second getUsers call (in catch) returns cached.
        var callCount = 0;
        when(mockUserLocalService.getUsers()).thenAnswer((_) async {
          callCount++;
          // First call (inside try): empty → proceeds to checkConnection.
          // The exception is thrown by checkConnection, not getUsers.
          return callCount == 1 ? <UserModel>[] : tLocalUsers;
        });
        when(
          mockConnectionService.checkConnection(),
        ).thenThrow(Exception('Network failure'));

        // act
        final result = await repository.findAllUsers();

        // assert
        expect(result, isA<SuccessResult<List<UserModel>, Exception>>());
        final users =
            (result as SuccessResult<List<UserModel>, Exception>).value;
        expect(users.first.name, equals(tLocalUsers.first.name));
      });

      test(
        'should return ErrorResult with unexpected error message '
        'when an exception is thrown and local cache is also empty',
        () async {
          // arrange
          when(
            mockUserLocalService.getUsers(),
          ).thenAnswer((_) async => <UserModel>[]);
          when(
            mockConnectionService.checkConnection(),
          ).thenThrow(Exception('Network failure'));

          // act
          final result = await repository.findAllUsers();

          // assert
          expect(result, isA<ErrorResult<List<UserModel>, Exception>>());
          final error =
              (result as ErrorResult<List<UserModel>, Exception>).error;
          expect(error.toString(), contains('Unexpected error'));
        },
      );

      test('should call getUsers twice when an exception occurs — '
          'once in the try block and once in the catch block', () async {
        // arrange
        when(
          mockUserLocalService.getUsers(),
        ).thenAnswer((_) async => <UserModel>[]);
        when(
          mockConnectionService.checkConnection(),
        ).thenThrow(Exception('Network failure'));

        // act
        await repository.findAllUsers();

        // assert
        verify(mockUserLocalService.getUsers()).called(2);
      });
    });

    // ---------------------------------------------------------------------------
    // findAllUsers — Result.fold integration
    // ---------------------------------------------------------------------------

    group('findAllUsers — fold', () {
      test('should allow fold to extract user list on SuccessResult', () async {
        // arrange
        stubLocalEmpty();
        stubConnected();
        stubHttp200();
        when(mockUserLocalService.clearUsers()).thenAnswer((_) async {
          return;
        });
        when(mockUserLocalService.saveUsers(any)).thenAnswer((_) async {
          return;
        });

        // act
        final result = await repository.findAllUsers();
        final users = result.fold(
          onSuccess: (value) => value,
          onError: (_) => <UserModel>[],
        );

        // assert
        expect(users, isNotEmpty);
        expect(users.first.email, equals(tRemoteUsers.first.email));
      });

      test('should allow fold to return empty list on ErrorResult', () async {
        // arrange
        stubLocalEmpty();
        stubDisconnected();

        // act
        final result = await repository.findAllUsers();
        final users = result.fold(
          onSuccess: (value) => value,
          onError: (_) => <UserModel>[],
        );

        // assert
        expect(users, isEmpty);
      });
    });
  });
}
