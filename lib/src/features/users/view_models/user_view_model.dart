import 'package:offline_first_app/src/common/states/state.dart';
import 'package:offline_first_app/src/features/users/models/user_model.dart';
import 'package:offline_first_app/src/features/users/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';

typedef _ViewModel = ChangeNotifier;

typedef UsersState = AppState<List<UserModel>>;

abstract interface class UserViewModel extends _ViewModel {
  UsersState get userState;

  Future<void> getAllUsers();
}

class UserViewModelImpl extends _ViewModel implements UserViewModel {
  final UserRepository userRepository;

  UserViewModelImpl({required this.userRepository});

  UsersState _userState = InitialState();

  @override
  UsersState get userState => _userState;

  @override
  Future<void> getAllUsers() async {
    _emit(LoadingState());

    final result = await userRepository.findAllUsers();

    final state = result.fold<UsersState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(message: '$error'),
    );

    _emit(state);
  }

  void _emit(UsersState newValue) {
    if (_userState != newValue) {
      _userState = newValue;
      notifyListeners();
      debugPrint('User state: $_userState');
    }
  }
}
