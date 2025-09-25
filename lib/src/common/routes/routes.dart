import 'package:go_router/go_router.dart';
import 'package:offline_first_app/src/features/settings/routes/setting_routes.dart';
import 'package:offline_first_app/src/features/users/routes/user_routes.dart';

class Routes {
  static String get home => UserRoutes.users;

  GoRouter get routes => _routes;

  final GoRouter _routes = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: home,
    routes: [...UserRoutes().routes, ...SettingRoutes().routes],
  );
}
