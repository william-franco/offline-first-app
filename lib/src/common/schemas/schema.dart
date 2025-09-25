class TableSchema {
  final String tableName;
  final List<TableColumn> columns;
  final List<TableForeignKey> foreignKeys;

  TableSchema({
    required this.tableName,
    required this.columns,
    required this.foreignKeys,
  });

  String createTableQuery() {
    final columnsQuery = columns
        .map((col) => col.createColumnQuery())
        .join(', ');
    final foreignKeysQuery = foreignKeys
        .map((fk) => fk.createForeignKeyQuery())
        .join(', ');
    final body = [
      if (columnsQuery.isNotEmpty) columnsQuery,
      if (foreignKeysQuery.isNotEmpty) foreignKeysQuery,
    ].join(', ');

    return 'CREATE TABLE IF NOT EXISTS $tableName ($body);';
  }
}

class TableColumn {
  final String name;
  final String type;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool isAutoIncrement;
  final Object? defaultValue;

  TableColumn({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isNullable = true,
    this.isAutoIncrement = false,
    this.defaultValue,
  });

  String createColumnQuery() {
    String query = '$name $type';
    if (!isNullable) query += ' NOT NULL';
    if (isPrimaryKey) query += ' PRIMARY KEY';
    if (isAutoIncrement) query += ' AUTOINCREMENT';

    if (defaultValue != null) {
      if (defaultValue is bool) {
        // SQLite doesn't have boolean type: use 1/0
        query += ' DEFAULT ${defaultValue != null ? 1 : 0}';
      } else if (defaultValue is num) {
        query += ' DEFAULT $defaultValue';
      } else if (defaultValue is String) {
        final val = defaultValue as String;
        // Treat uppercase-only words (like CURRENT_TIMESTAMP) as SQL keywords
        final isSqlKeyword = RegExp(r'^[A-Z0-9_]+$').hasMatch(val);
        query += isSqlKeyword ? ' DEFAULT $val' : " DEFAULT '$val'";
      } else {
        query += " DEFAULT '${defaultValue.toString()}'";
      }
    }

    return query;
  }
}

class TableForeignKey {
  final String column;
  final String foreignTable;
  final String foreignColumn;
  final String? onDelete; // optional (e.g., 'CASCADE')

  TableForeignKey({
    required this.column,
    required this.foreignTable,
    required this.foreignColumn,
    this.onDelete,
  });

  String createForeignKeyQuery() {
    final onDeleteClause = onDelete != null ? ' ON DELETE $onDelete' : '';
    return 'FOREIGN KEY ($column) REFERENCES $foreignTable($foreignColumn)$onDeleteClause';
  }
}
