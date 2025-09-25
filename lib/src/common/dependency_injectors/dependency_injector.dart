import 'package:offline_first_app/src/common/services/connection_service.dart';
import 'package:offline_first_app/src/common/services/database_service.dart';
import 'package:offline_first_app/src/common/services/http_service.dart';
import 'package:offline_first_app/src/common/services/storage_service.dart';
import 'package:offline_first_app/src/features/settings/repositories/setting_repository.dart';
import 'package:offline_first_app/src/features/settings/view_models/setting_view_model.dart';
import 'package:offline_first_app/src/features/users/view_models/user_view_model.dart';
import 'package:offline_first_app/src/features/users/repositories/user_repository.dart';
import 'package:offline_first_app/src/features/users/services/user_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void dependencyInjector() {
  _startConnectionService();
  _startDataBaseService();
  _startHttpService();
  _startStorageService();
  _startFeatureUser();
  _startFeatureSetting();
}

void _startConnectionService() {
  locator.registerLazySingleton<ConnectionService>(
    () => ConnectionServiceImpl(),
  );
}

void _startDataBaseService() {
  locator.registerLazySingleton<DatabaseLocationService>(
    () => DatabaseLocationServiceImpl(),
  );
  locator.registerLazySingleton<DatabaseTablesService>(
    () => DatabaseTablesServiceImpl(),
  );
  locator.registerLazySingleton<DatabaseHelper>(
    () => DatabaseHelperImpl(
      locationService: locator<DatabaseLocationService>(),
      tablesService: locator<DatabaseTablesService>(),
    ),
  );
  locator.registerLazySingleton<DatabaseService>(
    () => DatabaseServiceImpl(
      locationService: locator<DatabaseLocationService>(),
      tablesService: locator<DatabaseTablesService>(),
    ),
  );
}

void _startHttpService() {
  locator.registerLazySingleton<HttpService>(() => HttpServiceImpl());
}

void _startStorageService() {
  locator.registerLazySingleton<StorageService>(() => StorageServiceImpl());
}

void _startFeatureUser() {
  locator.registerLazySingleton<UserLocalService>(
    () => UserLocalServiceImpl(databaseHelper: locator<DatabaseHelper>()),
  );
  locator.registerCachedFactory<UserRepository>(
    () => UserRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
      userLocalService: locator<UserLocalService>(),
    ),
  );
  locator.registerLazySingleton<UserViewModel>(
    () => UserViewModelImpl(userRepository: locator<UserRepository>()),
  );
}

void _startFeatureSetting() {
  locator.registerCachedFactory<SettingRepository>(
    () => SettingRepositoryImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<SettingViewModel>(
    () => SettingViewModelImpl(settingRepository: locator<SettingRepository>()),
  );
}

Future<void> initDependencies() async {
  await Future.wait([
    locator<ConnectionService>().checkConnection(),
    locator<DatabaseService>().initialize(),
    locator<StorageService>().initStorage(),
  ]);
  await locator<SettingViewModel>().getTheme();
}

void resetDependencies() {
  locator.reset();
}

void resetFeatureSetting() {
  locator.unregister<SettingRepository>();
  locator.unregister<SettingViewModel>();
  _startFeatureSetting();
}
