import '../input_utils.dart';

Future<String> promptDomainName() async {
  String? domainName;
  while (domainName == null || domainName.isEmpty) {
    domainName = readLinePrompt('Enter the main domain name for this project: ');
    if (domainName == null || domainName.trim().isEmpty) {
      print('Domain name cannot be empty.');
      domainName = null;
    }
  }
  return domainName;
}
