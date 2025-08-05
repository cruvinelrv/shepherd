import 'dart:io';

/// Asks the user if they want to enable microfrontends support and creates the microfrontends.yaml file if needed.
Future<void> promptInitMicrofrontends() async {
  while (true) {
    stdout.write('Enable microfrontends support? (y/N): ');
    final microResp = stdin.readLineSync()?.trim().toLowerCase();
    if (microResp == 'y' || microResp == 'yes') {
      final dir = Directory('dev_tools/shepherd');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final mfFile = File('dev_tools/shepherd/microfrontends.yaml');
      if (!mfFile.existsSync()) {
        mfFile.writeAsStringSync('microfrontends: []\n');
        print('File dev_tools/shepherd/microfrontends.yaml created.');
      } else {
        print('dev_tools/shepherd/microfrontends.yaml already exists.');
      }
      break;
    } else if (microResp == 'n' ||
        microResp == 'no' ||
        microResp == '' ||
        microResp == null) {
      // Do not enable microfrontends, just exit
      break;
    } else {
      print('Please answer only with yes (y/yes) or no (n/no).');
    }
  }
}
