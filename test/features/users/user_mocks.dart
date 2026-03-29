import 'package:mockito/annotations.dart';
import 'package:offline_first_app/src/common/services/connection_service.dart';
import 'package:offline_first_app/src/common/services/http_service.dart';
import 'package:offline_first_app/src/features/users/repositories/user_repository.dart';
import 'package:offline_first_app/src/features/users/services/user_service.dart';

@GenerateMocks([
  ConnectionService,
  HttpService,
  UserLocalService,
  UserRepository,
])
void main() {}
