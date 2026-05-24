import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:offline_first_app/src/common/patterns/app_state_pattern.dart';
import 'package:offline_first_app/src/common/patterns/result_pattern.dart';
import 'package:offline_first_app/src/features/users/exceptions/user_exception.dart';
import 'package:offline_first_app/src/features/users/models/user_model.dart';
import 'package:offline_first_app/src/features/users/repositories/user_repository.dart';
import 'package:offline_first_app/src/features/users/view_models/user_view_model.dart';

import '../user_mocks.mocks.dart';

void main() {
  group('UserViewModel Test', () {
    late MockUserRepository mockUserRepository;
    late UserViewModel viewModel;

    final dummySuccess = SuccessResult<List<UserModel>, UserException>(value: []);
    final dummyError = ErrorResult<List<UserModel>, UserException>(
      error: UserException('dummy'),
    );

    setUpAll(() {
      provideDummy<UserResult>(dummySuccess);
      provideDummy<UserResult>(dummyError);
    });

    setUp(() {
      mockUserRepository = MockUserRepository();
      viewModel = UserViewModelImpl(userRepository: mockUserRepository);
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ---------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------

    final tUsers = [
      UserModel(
        id: 1,
        name: 'Leanne Graham',
        username: 'Bret',
        email: 'Sincere@april.biz',
      ),
      UserModel(
        id: 2,
        name: 'Ervin Howell',
        username: 'Antonette',
        email: 'Shanna@melissa.tv',
      ),
    ];

    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------

    test('should start with InitialState', () {
      expect(viewModel.state, isA<InitialState<List<UserModel>, UserException>>());
    });

    // ---------------------------------------------------------------------------
    // getAllUsers
    // ---------------------------------------------------------------------------

    group('getAllUsers', () {
      test('should emit [LoadingState, SuccessState] '
          'when repository returns SuccessResult', () async {
        // arrange
        when(
          mockUserRepository.findAllUsers(),
        ).thenAnswer((_) async => SuccessResult(value: tUsers));

        final emittedStates = <UsersState>[];
        viewModel.addListener(() => emittedStates.add(viewModel.state));

        // act
        await viewModel.getAllUsers();

        // assert
        expect(emittedStates.length, equals(2));
        expect(emittedStates[0], isA<LoadingState<List<UserModel>, UserException>>());
        expect(emittedStates[1], isA<SuccessState<List<UserModel>, UserException>>());

        final success = emittedStates[1] as SuccessState<List<UserModel>, UserException>;
        expect(success.data.length, equals(tUsers.length));
        expect(success.data.first.name, equals(tUsers.first.name));
        verify(mockUserRepository.findAllUsers()).called(1);
      });

      test('should emit [LoadingState, SuccessState] with cached users '
          'when repository returns SuccessResult from local cache', () async {
        // arrange — simulates offline + cache hit path in the repository
        final cachedUsers = [
          UserModel(id: 99, name: 'Cached User', username: 'cache'),
        ];
        when(
          mockUserRepository.findAllUsers(),
        ).thenAnswer((_) async => SuccessResult(value: cachedUsers));

        final emittedStates = <UsersState>[];
        viewModel.addListener(() => emittedStates.add(viewModel.state));

        // act
        await viewModel.getAllUsers();

        // assert
        expect(emittedStates[1], isA<SuccessState<List<UserModel>, UserException>>());
        final success = emittedStates[1] as SuccessState<List<UserModel>, UserException>;
        expect(success.data.first.name, equals('Cached User'));
      });

      test('should emit [LoadingState, ErrorState] '
          'when repository returns ErrorResult', () async {
        // arrange
        when(mockUserRepository.findAllUsers()).thenAnswer(
          (_) async => ErrorResult(error: UserException('Device not connected.')),
        );

        final emittedStates = <UsersState>[];
        viewModel.addListener(() => emittedStates.add(viewModel.state));

        // act
        await viewModel.getAllUsers();

        // assert
        expect(emittedStates[0], isA<LoadingState<List<UserModel>, UserException>>());
        expect(emittedStates[1], isA<ErrorState<List<UserModel>, UserException>>());

        final error = emittedStates[1] as ErrorState<List<UserModel>, UserException>;
        expect(error.error.message, contains('Device not connected.'));
      });

      test('should emit [LoadingState, ErrorState] '
          'when repository returns unexpected error', () async {
        // arrange
        when(mockUserRepository.findAllUsers()).thenAnswer(
          (_) async => ErrorResult(error: UserException('Unexpected error')),
        );

        final emittedStates = <UsersState>[];
        viewModel.addListener(() => emittedStates.add(viewModel.state));

        // act
        await viewModel.getAllUsers();

        // assert
        expect(emittedStates[1], isA<ErrorState<List<UserModel>, UserException>>());
        final error = emittedStates[1] as ErrorState<List<UserModel>, UserException>;
        expect(error.error.message, contains('Unexpected error'));
      });

      test('should emit SuccessState with empty list '
          'when repository returns an empty SuccessResult', () async {
        // arrange
        when(
          mockUserRepository.findAllUsers(),
        ).thenAnswer((_) async => SuccessResult(value: <UserModel>[]));

        final emittedStates = <UsersState>[];
        viewModel.addListener(() => emittedStates.add(viewModel.state));

        // act
        await viewModel.getAllUsers();

        // assert
        final success = emittedStates[1] as SuccessState<List<UserModel>, UserException>;
        expect(success.data, isEmpty);
      });

      test(
        'should notify listeners exactly twice per getAllUsers call',
        () async {
          // arrange
          when(
            mockUserRepository.findAllUsers(),
          ).thenAnswer((_) async => SuccessResult(value: tUsers));

          int notifyCount = 0;
          viewModel.addListener(() => notifyCount++);

          // act
          await viewModel.getAllUsers();

          // assert
          expect(notifyCount, equals(2));
        },
      );

      test(
        'should have LoadingState while repository call is in progress',
        () async {
          // arrange
          UsersState? stateWhileLoading;
          when(mockUserRepository.findAllUsers()).thenAnswer((_) async {
            stateWhileLoading = viewModel.state;
            return SuccessResult(value: tUsers);
          });

          // act
          await viewModel.getAllUsers();

          // assert
          expect(stateWhileLoading, isA<LoadingState<List<UserModel>, UserException>>());
        },
      );

      test(
        'should reset to LoadingState on each new getAllUsers call',
        () async {
          // arrange
          when(
            mockUserRepository.findAllUsers(),
          ).thenAnswer((_) async => SuccessResult(value: tUsers));

          await viewModel.getAllUsers();
          expect(viewModel.state, isA<SuccessState<List<UserModel>, UserException>>());

          when(mockUserRepository.findAllUsers()).thenAnswer(
            (_) async => ErrorResult(error: UserException('Server error')),
          );

          // act
          await viewModel.getAllUsers();

          // assert
          expect(viewModel.state, isA<ErrorState<List<UserModel>, UserException>>());
          verify(mockUserRepository.findAllUsers()).called(2);
        },
      );
    });
  });
}
