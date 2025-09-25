import 'package:offline_first_app/src/common/enums/database_enum.dart';
import 'package:offline_first_app/src/common/services/database_service.dart';
import 'package:offline_first_app/src/features/users/models/user_model.dart';

abstract interface class UserLocalService {
  Future<void> saveUsers(List<UserModel> users);
  Future<List<UserModel>> getUsers();
  Future<void> clearUsers();
}

class UserLocalServiceImpl implements UserLocalService {
  final DatabaseHelper databaseHelper;

  UserLocalServiceImpl({required this.databaseHelper});

  @override
  Future<void> saveUsers(List<UserModel> users) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      for (final user in users) {
        int? geoId;
        if (user.address?.geo != null) {
          geoId = await txn.insert(
            DBTables.geoTable.name,
            user.address!.geo!.toJson(),
          );
        }

        int? addressId;
        if (user.address != null) {
          final addressData = user.address!.toJson();
          addressData.remove('geo');
          addressId = await txn.insert(DBTables.addressTable.name, {
            ...addressData,
            'geo_id': geoId,
          });
        }

        int? companyId;
        if (user.company != null) {
          companyId = await txn.insert(
            DBTables.companyTable.name,
            user.company!.toJson(),
          );
        }

        final userData = user.toJson();
        userData.remove('address');
        userData.remove('company');

        await txn.insert(DBTables.userTable.name, {
          ...userData,
          'address_id': addressId,
          'company_id': companyId,
        });
      }
    });
  }

  @override
  Future<List<UserModel>> getUsers() async {
    final db = await databaseHelper.database;

    final userRows = await db.query(DBTables.userTable.name);
    final List<UserModel> users = [];

    for (final userRow in userRows) {
      Map<String, dynamic>? addressData;
      Map<String, dynamic>? companyData;
      Map<String, dynamic>? geoData;

      if (userRow['address_id'] != null) {
        final addressResult = await db.query(
          DBTables.addressTable.name,
          where: 'id = ?',
          whereArgs: [userRow['address_id']],
          limit: 1,
        );

        if (addressResult.isNotEmpty) {
          addressData = Map<String, dynamic>.from(addressResult.first);

          if (addressData['geo_id'] != null) {
            final geoResult = await db.query(
              DBTables.geoTable.name,
              where: 'id = ?',
              whereArgs: [addressData['geo_id']],
              limit: 1,
            );

            if (geoResult.isNotEmpty) {
              geoData = Map<String, dynamic>.from(geoResult.first);
              addressData['geo'] = geoData;
            }
          }
        }
      }

      if (userRow['company_id'] != null) {
        final companyResult = await db.query(
          DBTables.companyTable.name,
          where: 'id = ?',
          whereArgs: [userRow['company_id']],
          limit: 1,
        );

        if (companyResult.isNotEmpty) {
          companyData = Map<String, dynamic>.from(companyResult.first);
        }
      }

      users.add(
        UserModel.fromJson({
          ...Map<String, dynamic>.from(userRow),
          'address': addressData,
          'company': companyData,
        }),
      );
    }

    return users;
  }

  @override
  Future<void> clearUsers() async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete(DBTables.geoTable.name);
      await txn.delete(DBTables.userTable.name);
      await txn.delete(DBTables.addressTable.name);
      await txn.delete(DBTables.companyTable.name);
    });
  }
}
