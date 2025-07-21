import 'dart:io';
import 'package:shepherd/src/data/datasources/local/config_database.dart';

ConfigDatabase openConfigDb() {
  return ConfigDatabase(Directory.current.path);
}
