import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Since path_provider needs flutter engine, we can't easily use it in pure dart script.
  // Let's just print Directory.current.path
  print("Current path: ${Directory.current.path}");
}
