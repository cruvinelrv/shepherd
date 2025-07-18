import 'package:shepherd/src/domain/usecases/analyze_usecase.dart';

class AnalyzeController {
  final AnalyzeUseCase useCase;
  AnalyzeController(this.useCase);

  Future<void> run() async {
    final results = await useCase.analyzeDomains();
    if (results.isEmpty) {
      print('Nenhum domínio para analisar.');
      return;
    }
    print('Resultado da análise dos domínios:');
    for (final result in results) {
      print('---');
      print('Domínio: ${result.domainName}');
      if (result.warnings.isNotEmpty) {
        print('Avisos:');
        for (final warning in result.warnings) {
          print('  - $warning');
        }
      } else {
        print('Nenhum aviso encontrado.');
      }
    }
  }
}
