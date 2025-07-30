import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';

DomainsDatabase openDomainsDb() {
  return DomainsDatabase(Directory.current.path);
}
