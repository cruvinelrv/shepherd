import 'dart:io';

/// Pergunta ao usuário se deseja ativar microfrontends e cria o arquivo microfrontends.yaml se necessário.
Future<void> promptInitMicrofrontends() async {
  stdout.write('Deseja ativar suporte a microfrontends? (s/N): ');
  final microResp = stdin.readLineSync()?.trim().toLowerCase();
  if (microResp == 's' || microResp == 'sim' || microResp == 'y' || microResp == 'yes') {
    final dir = Directory('dev_tools/shepherd');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final mfFile = File('dev_tools/shepherd/microfrontends.yaml');
    if (!mfFile.existsSync()) {
      mfFile.writeAsStringSync('microfrontends: []\n');
      print('Arquivo dev_tools/shepherd/microfrontends.yaml criado.');
    } else {
      print('dev_tools/shepherd/microfrontends.yaml já existe.');
    }
  }
}
