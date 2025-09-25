enum DBTables {
  geoTable,
  addressTable,
  companyTable,
  userTable;

  String get name {
    return switch (this) {
      DBTables.geoTable => 'geo',
      DBTables.addressTable => 'address',
      DBTables.companyTable => 'company',
      DBTables.userTable => 'user',
    };
  }
}
