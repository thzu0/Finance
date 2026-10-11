import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, Budgets, Notifications, UnparsedSmsMessages],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.source);
        await m.addColumn(transactions, transactions.bankName);
        await m.addColumn(transactions, transactions.accountLast4);
        await m.addColumn(transactions, transactions.balanceAfterRial);
        await m.addColumn(transactions, transactions.smsId);
        // SQLite اجازه‌ی UNIQUE روی ADD COLUMN نمی‌ده؛ پس index جدا
        await m.createIndex(transactionsSmsId);
        await customStatement(
          "UPDATE transactions SET source = "
          "CASE WHEN note LIKE 'پیامک%' THEN 'sms' ELSE 'manual' END",
        );
      }
      if (from < 3) {
        await m.createTable(unparsedSmsMessages);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
