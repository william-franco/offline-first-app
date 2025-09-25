import 'package:offline_first_app/src/common/constants/api_constant.dart';
import 'package:offline_first_app/src/common/results/result.dart';
import 'package:offline_first_app/src/common/services/connection_service.dart';
import 'package:offline_first_app/src/common/services/http_service.dart';
import 'package:offline_first_app/src/features/users/models/user_model.dart';
import 'package:offline_first_app/src/features/users/services/user_service.dart';

typedef UserResult = Result<List<UserModel>, Exception>;

abstract interface class UserRepository {
  Future<UserResult> findAllUsers();
}

class UserRepositoryImpl implements UserRepository {
  final HttpService httpService;
  final ConnectionService connectionService;
  final UserLocalService userLocalService;

  UserRepositoryImpl({
    required this.httpService,
    required this.connectionService,
    required this.userLocalService,
  });

  @override
  Future<UserResult> findAllUsers() async {
    try {
      final usersLocal = await userLocalService.getUsers();

      await connectionService.checkConnection();

      if (!connectionService.isConnected && usersLocal.isEmpty) {
        return ErrorResult(error: Exception('Device not connected.'));
      }

      if (!connectionService.isConnected && usersLocal.isNotEmpty) {
        return SuccessResult(value: usersLocal);
      }

      final result = await httpService.getData(path: ApiConstant.users);

      if (result.statusCode == 200 && result.data != null) {
        final usersRemote = (result.data as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();

        await userLocalService.clearUsers();
        await userLocalService.saveUsers(usersRemote);

        return SuccessResult(value: usersRemote);
      }

      return ErrorResult(
        error: Exception('Failed to fetch users: ${result.statusCode}'),
      );
    } catch (error) {
      final usersLocal = await userLocalService.getUsers();

      if (usersLocal.isNotEmpty) {
        return SuccessResult(value: usersLocal);
      }

      return ErrorResult(error: Exception('Unexpected error: $error'));
    }
  }
}
