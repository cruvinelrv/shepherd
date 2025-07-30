import 'package:shepherd/src/domains/domain/usecases/list_usecase.dart';

/// Use case for exporting domains and owners to YAML.
class ExportYamlUseCase {
  final dynamic domainsDb;
  ExportYamlUseCase(this.domainsDb);

  /// Returns all domains and their owners as a list of maps.
  Future<List<Map<String, dynamic>>> getDomainsWithOwners() async {
    // Reuses ListUseCase to get the data
    final listUseCase = ListUseCase(domainsDb);
    return await listUseCase.getDomainsWithOwners();
  }
}
