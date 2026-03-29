import 'package:mockito/annotations.dart';
import 'package:offline_first_app/src/common/services/storage_service.dart';
import 'package:offline_first_app/src/features/settings/repositories/setting_repository.dart';

@GenerateMocks([StorageService, SettingRepository])
void main() {}
