import 'package:sqflite/sqflite.dart';

import 'package:dictionary_editor/objects/language.dart';
import 'database.dart';

bool _to_bool(String? value) => value! == "true";

int _to_int(String? value) => int.parse(value!);

double _to_double(String? value) => double.parse(value!);

double? _to_nullable_double(String? value) => value != null && value != "null" ? double.parse(value) : null;

class LanguageDatabaseManager extends SubDatabaseManager {
  static const String KEY_COLUMN = "key";
  static const String VALUE_COLUMN = "value";

  static final LanguageDatabaseManager _singleton = LanguageDatabaseManager._create_singleton();

  LanguageDatabaseManager._create_singleton() {
    setup_stream();
  }

  factory LanguageDatabaseManager() => _singleton;

  static Map<String, String?> combine_settings_rows(List<Map<String, dynamic>> rows) {
    return Map.fromIterable(rows, key: (row) => row[KEY_COLUMN]!, value: (row) => row[VALUE_COLUMN]);
  }

  Future<Language> get_language() async {
    await db_is_open;
    return map_to_language(combine_settings_rows(await database.query("configuration")));
  }

  Future update_value(String key, dynamic value) async {
    await db_is_open;
    Map<String, String?> row = {KEY_COLUMN: key, VALUE_COLUMN: value?.toString()};
    await database.insert("configuration", row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Language map_to_language(Map<String, String?> map) {
    return Language(
      conlang_name: map[Language.CONLANG_NAME_SETTING],
      baselang_name: map[Language.BASELANG_NAME_SETTING],
      conlang_font: map[Language.CONLANG_FONT_SETTING],
      base_conlang_font_size: _to_nullable_double(map[Language.BASE_CONLANG_FONT_SIZE_SETTING]),
      baselang_font: map[Language.BASELANG_FONT_SETTING],
      base_baselang_font_size: _to_nullable_double(map[Language.BASE_BASELANG_FONT_SIZE_SETTING]),
    );
  }
}
