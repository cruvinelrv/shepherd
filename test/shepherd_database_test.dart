import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('ShepherdDatabase', () {
    late ShepherdDatabase db;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      db = ShepherdDatabase(tempDir.path);
      await db.database; // Ensure DB is initialized
    });
    tearDown(() async {
      await db.close();
    });

    test('insertPerson and getAllPersons', () async {
      final id = await db.insertPerson(
        firstName: 'Test',
        lastName: 'User',
        email: 'test.user@example.com',
        type: 'developer',
        githubUsername: 'testuser',
      );
      final persons = await db.getAllPersons();
      expect(persons, isNotEmpty);
      expect(persons.first['id'], equals(id));
      expect(persons.first['first_name'], equals('Test'));
    });
  });
}
