import 'package:flutter/foundation.dart';
import 'package:offline_first_app/src/common/enums/database_enum.dart';
import 'package:offline_first_app/src/common/schemas/schema.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class DatabaseLocationService {
  Future<String> getDatabasePath();
}

class DatabaseLocationServiceImpl implements DatabaseLocationService {
  @override
  Future<String> getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'app_database.db');
  }
}

abstract interface class DatabaseTablesService {
  Future<void> createTables(Transaction transaction);
}

class DatabaseTablesServiceImpl implements DatabaseTablesService {
  DatabaseTablesServiceImpl();

  @override
  Future<void> createTables(Transaction transaction) async {
    debugPrint('Creating tables...');
    await _createGeoTable(transaction);
    await _createAddressTable(transaction);
    await _createCompanyTable(transaction);
    await _createUserTable(transaction);
    debugPrint('All tables creation executed.');
  }

  Future<void> _createGeoTable(Transaction transaction) async {
    final schema = TableSchema(
      tableName: DBTables.geoTable.name,
      columns: [
        TableColumn(
          name: 'id',
          type: 'INTEGER',
          isPrimaryKey: true,
          isAutoIncrement: true,
        ),
        TableColumn(name: 'lat', type: 'TEXT'),
        TableColumn(name: 'lng', type: 'TEXT'),
      ],
      foreignKeys: [],
    );
    await transaction.execute(schema.createTableQuery());
    debugPrint('Geo table created.');
  }

  Future<void> _createAddressTable(Transaction transaction) async {
    final schema = TableSchema(
      tableName: DBTables.addressTable.name,
      columns: [
        TableColumn(
          name: 'id',
          type: 'INTEGER',
          isPrimaryKey: true,
          isAutoIncrement: true,
        ),
        TableColumn(name: 'street', type: 'TEXT'),
        TableColumn(name: 'suite', type: 'TEXT'),
        TableColumn(name: 'city', type: 'TEXT'),
        TableColumn(name: 'zipcode', type: 'TEXT'),
        TableColumn(name: 'geo_id', type: 'INTEGER'),
      ],
      foreignKeys: [
        TableForeignKey(
          column: 'geo_id',
          foreignTable: DBTables.geoTable.name,
          foreignColumn: 'id',
          onDelete: 'SET NULL',
        ),
      ],
    );
    await transaction.execute(schema.createTableQuery());
    debugPrint('Address table created.');
  }

  Future<void> _createCompanyTable(Transaction transaction) async {
    final schema = TableSchema(
      tableName: DBTables.companyTable.name,
      columns: [
        TableColumn(
          name: 'id',
          type: 'INTEGER',
          isPrimaryKey: true,
          isAutoIncrement: true,
        ),
        TableColumn(name: 'name', type: 'TEXT'),
        TableColumn(name: 'catchPhrase', type: 'TEXT'),
        TableColumn(name: 'bs', type: 'TEXT'),
      ],
      foreignKeys: [],
    );
    await transaction.execute(schema.createTableQuery());
    debugPrint('Company table created.');
  }

  Future<void> _createUserTable(Transaction transaction) async {
    final schema = TableSchema(
      tableName: DBTables.userTable.name,
      columns: [
        TableColumn(
          name: 'id',
          type: 'INTEGER',
          isPrimaryKey: true,
          isAutoIncrement: true,
        ),
        TableColumn(name: 'name', type: 'TEXT'),
        TableColumn(name: 'username', type: 'TEXT'),
        TableColumn(name: 'email', type: 'TEXT'),
        TableColumn(name: 'phone', type: 'TEXT'),
        TableColumn(name: 'website', type: 'TEXT'),
        TableColumn(name: 'address_id', type: 'INTEGER'),
        TableColumn(name: 'company_id', type: 'INTEGER'),
      ],
      foreignKeys: [
        TableForeignKey(
          column: 'address_id',
          foreignTable: DBTables.addressTable.name,
          foreignColumn: 'id',
          onDelete: 'SET NULL',
        ),
        TableForeignKey(
          column: 'company_id',
          foreignTable: DBTables.companyTable.name,
          foreignColumn: 'id',
          onDelete: 'SET NULL',
        ),
      ],
    );
    await transaction.execute(schema.createTableQuery());
    debugPrint('User table created.');
  }
}

abstract interface class DatabaseHelper {
  Future<Database> get database;
  Future<void> close();
}

class DatabaseHelperImpl implements DatabaseHelper {
  final DatabaseLocationService _locationService;
  final DatabaseTablesService _tablesService;

  DatabaseHelperImpl({
    required DatabaseLocationService locationService,
    required DatabaseTablesService tablesService,
  }) : _locationService = locationService,
       _tablesService = tablesService;

  static Database? _database;

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = await _locationService.getDatabasePath();
    return await openDatabase(path, version: 1, onCreate: _onCreateNew);
  }

  Future<void> _onCreateNew(Database db, int version) async {
    await db.transaction((txn) async {
      await _tablesService.createTables(txn);
    });
  }

  @override
  Future<void> close() async {
    final db = await database;
    await db.close();
    debugPrint('Database closed.');
  }
}

abstract interface class DatabaseService {
  Future<void> initialize();
  Future<void> truncateDB(Database db);
  Future<void> createTables(Database db);
  Future<bool> batch(String table, Iterable<Map<String, dynamic>> listData);
  Future<int> count(String table, {String? aditionalWhere});
}

class DatabaseServiceImpl implements DatabaseService {
  final DatabaseLocationService _locationService;
  final DatabaseTablesService _tablesService;

  DatabaseServiceImpl({
    required DatabaseLocationService locationService,
    required DatabaseTablesService tablesService,
  }) : _locationService = locationService,
       _tablesService = tablesService;

  int version = 1;
  bool forceRecreate = false;
  late Database database;

  @override
  Future<void> initialize() async {
    await _initializeDB();
    if (forceRecreate) {
      final db = await openDatabase(
        await _locationService.getDatabasePath(),
        version: version,
      );
      await truncateDB(db);
      await createTables(db);
    }
  }

  Future<void> _initializeDB() async {
    final db = await openDatabase(
      await _locationService.getDatabasePath(),
      version: version,
      onUpgrade: _onUpgrade,
      onCreate: _onCreate,
    );
    database = db;
    debugPrint('Database initialized.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion...');
    database = db;
    await truncateDB(db);
    await createTables(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database (onCreate handler)...');
    await createTables(db);
  }

  @override
  Future<void> truncateDB(Database db) async {
    debugPrint('Truncating database...');
    List<Map<String, dynamic>> tables = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = "table" AND name NOT LIKE "sqlite_%"',
    );

    Batch batch = db.batch();
    for (var table in tables) {
      var tableName = table['name'];
      debugPrint('Dropping table: $tableName');
      batch.execute('DROP TABLE IF EXISTS $tableName');
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> createTables(Database db) async {
    await db.transaction((txn) async {
      await _tablesService.createTables(txn);
    });
    debugPrint('Tables created.');
  }

  @override
  Future<bool> batch(
    String table,
    Iterable<Map<String, dynamic>> listData,
  ) async {
    try {
      debugPrint('Inserting data into $table...');
      final batch = database.batch();
      for (var element in listData) {
        batch.insert(
          table,
          element,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      debugPrint('Data inserted into $table successfully.');
      return true;
    } catch (e) {
      debugPrint('Error inserting data: $e');
      throw Exception(e.toString());
    }
  }

  @override
  Future<int> count(String table, {String? aditionalWhere}) async {
    try {
      debugPrint('Counting records in $table...');
      var response = await database.query(
        table,
        columns: ['count()'],
        where: aditionalWhere,
      );
      final count = (response.first['count()'] as num).toInt();
      debugPrint('Found $count records in $table.');
      return count;
    } catch (err) {
      debugPrint('Error counting records: $err');
      return 0;
    }
  }
}
