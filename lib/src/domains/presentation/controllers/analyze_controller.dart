import 'package:shepherd/src/domains/domain/usecases/analyze_usecase.dart';

/// Controller for domain analysis actions.
class AnalyzeController {
  final AnalyzeUseCase useCase;
  AnalyzeController(this.useCase);

  /// Runs the domain analysis and prints the results.
  Future<void> run() async {
    final results = await useCase.analyzeDomains();
    if (results.isEmpty) {
      print('No domains to analyze.');
      return;
    }
    print('Domain analysis results:');
    for (final result in results) {
      print('---');
      print('Domain: ${result.domainName}');
      if (result.warnings.isNotEmpty) {
        print('Warnings:');
        for (final warning in result.warnings) {
          print('  - $warning');
        }
      } else {
        print('No warnings found.');
      }
    }
  }
}
