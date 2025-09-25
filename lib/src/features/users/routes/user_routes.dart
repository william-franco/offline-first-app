import 'package:offline_first_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:offline_first_app/src/features/users/view_models/user_view_model.dart';
import 'package:offline_first_app/src/features/users/models/user_model.dart';
import 'package:offline_first_app/src/features/users/views/user_detail_view.dart';
import 'package:offline_first_app/src/features/users/views/user_view.dart';
import 'package:go_router/go_router.dart';

class UserRoutes {
  static String get users => '/users';
  static String get userDetail => '/users-detail';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: users,
      builder: (context, state) {
        return UserView(userViewModel: locator<UserViewModel>());
      },
    ),
    GoRoute(
      path: userDetail,
      builder: (context, state) {
        final UserModel userModel = state.extra as UserModel;

        return UserDetailView(userModel: userModel);
      },
    ),
  ];
}
