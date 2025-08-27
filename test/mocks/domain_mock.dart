import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';
import 'package:shepherd/src/domains/domain/entities/domain_health_entity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Manual mock for DomainsDatabase to be used in unit tests.

class MockDomainsDatabase implements DomainsDatabase {
  @override
  String projectPath = '/fake/path';

  // For test assertions
  bool insertCalled = false;
  Map<String, dynamic>? lastInsertArgs;

  // Injeta o mock de Database
  final MockDatabase mockDatabase;
  MockDomainsDatabase({MockDatabase? database})
      : mockDatabase = database ?? MockDatabase();

  @override
  Future<void> insertDomain({
    required String domainName,
    required double score,
    required int commits,
    required int days,
    required String warnings,
    required List<int> personIds,
    required String projectPath,
  }) async {
    insertCalled = true;
    lastInsertArgs = {
      'domainName': domainName,
      'score': score,
      'commits': commits,
      'days': days,
      'warnings': warnings,
      'personIds': personIds,
      'projectPath': projectPath,
    };
  }

  @override
  Future<Database> get database async => mockDatabase;

  // Stubs for all required methods
  @override
  Future<void> close() async => throw UnimplementedError();
  @override
  Future<void> deleteDomain(String domainName) async =>
      throw UnimplementedError();
  @override
  Future<List<DomainHealthEntity>> getAllDomainHealths() async =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getOwnersForDomain(
          String domainName) async =>
      throw UnimplementedError();
  @override
  Future<void> insertAnalysisLog({
    required int durationMs,
    required String status,
    required int totalDomains,
    required int unhealthyDomains,
    required String warnings,
  }) async =>
      throw UnimplementedError();
}

class MockDatabase implements Database {
  // For addPerson test
  bool insertPersonCalled = false;
  Map<String, Object?>? lastInsertPersonArgs;
  int insertPersonReturnId = 1;

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    if (table == 'persons') {
      insertPersonCalled = true;
      lastInsertPersonArgs = values;
      return insertPersonReturnId;
    }
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    // Return empty list for test
    return [];
  }

  // Stubs for all other Database methods
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
