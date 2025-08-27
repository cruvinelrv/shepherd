import 'package:test/test.dart';
import 'package:shepherd/src/domains/domain/usecases/add_owner_usecase.dart';
import '../../../../mocks/domain_mock.dart';

void main() {
  group('AddOwnerUseCase', () {
    late MockDomainsDatabase mockDb;
    late AddOwnerUseCase useCase;

    setUp(() {
      mockDb = MockDomainsDatabase();
      useCase = AddOwnerUseCase(mockDb);
    });

    test('createDomain calls insertDomain with correct values', () async {
      await useCase.createDomain('TestDomain');
      expect(mockDb.insertCalled, isTrue);
      expect(mockDb.lastInsertArgs?['domainName'], 'TestDomain');
      expect(mockDb.lastInsertArgs?['score'], 100.0);
      expect(mockDb.lastInsertArgs?['commits'], 0);
      expect(mockDb.lastInsertArgs?['days'], 0);
      expect(mockDb.lastInsertArgs?['warnings'], '');
      expect(mockDb.lastInsertArgs?['personIds'], []);
      expect(mockDb.lastInsertArgs?['projectPath'], '/fake/path');
    });

    test('addPerson calls insert on persons table with correct values',
        () async {
      mockDb.mockDatabase.insertPersonReturnId = 42;
      final id = await useCase.addPerson(
          'John', 'Doe', 'john@doe.com', 'developer', 'johndoe');
      expect(id, 42);
      expect(mockDb.mockDatabase.insertPersonCalled, isTrue);
      expect(mockDb.mockDatabase.lastInsertPersonArgs?['first_name'], 'John');
      expect(mockDb.mockDatabase.lastInsertPersonArgs?['last_name'], 'Doe');
      expect(
          mockDb.mockDatabase.lastInsertPersonArgs?['email'], 'john@doe.com');
      expect(mockDb.mockDatabase.lastInsertPersonArgs?['type'], 'developer');
      expect(mockDb.mockDatabase.lastInsertPersonArgs?['github_username'],
          'johndoe');
    });
  });
}
