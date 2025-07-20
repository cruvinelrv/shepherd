import 'dart:io';
import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';

/// Returns the current project path.
String getProjectPath() => Directory.current.path;

/// Opens a ShepherdDatabase for the current project path.
ShepherdDatabase openShepherdDb() => ShepherdDatabase(getProjectPath());
