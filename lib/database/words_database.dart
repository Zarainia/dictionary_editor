import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/database/database.dart';
import 'package:dictionary_editor/objects/word.dart';

class WordsDatabaseManager extends SubDatabaseManager {
  static const String WORDS_TABLE = "words";
  static const String TRANSLATIONS_TABLE = "translations";

  static final WordsDatabaseManager _singleton = WordsDatabaseManager._create_singleton();

  WordsDatabaseManager._create_singleton() {
    setup_stream();
  }

  factory WordsDatabaseManager() => _singleton;

  Future<Map<int, Word>> get_words() async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(WORDS_TABLE);
    return Map.fromEntries(await Future.wait(maps.map((map) async => MapEntry(map[Word.ID_COLUMN]!, await _resolve_word(map)))));
  }

  Future<Word> get_word(int word_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(WORDS_TABLE, where: "${Word.ID_COLUMN} = ?", whereArgs: [word_id]);
    assert(maps.length == 1);
    return _resolve_word(maps.first);
  }

  Future<Word> _resolve_word(Map<String, dynamic> map) async {
    return map_to_word(
      map,
      translations: await get_word_translations(map[Word.ID_COLUMN]!),
    );
  }

  static Word map_to_word(Map<String, dynamic> map, {List<Translation> translations = const []}) {
    return Word(
      id: map[Word.ID_COLUMN]!,
      name: map[Word.NAME_COLUMN]!,
      number: map[Word.NUMBER_COLUMN],
      pronunciation: empty_null(map[Word.PRONUNCIATION_COLUMN]),
      etymology: empty_null(map[Word.ETYMOLOGY_COLUMN]),
      notes: empty_null(map[Word.NOTES_COLUMN]),
      translations: translations.lock,
      audio: map[Word.AUDIO_COLUMN],
    );
  }

  Future<Map<String, dynamic>> _add_word_number(Map<String, dynamic> json, {DatabaseExecutor? database, int? word_id}) async {
    await db_is_open;
    database = database ?? this.database;
    String word = json[Word.NAME_COLUMN]!;

    List<Map<String, dynamic>> maps;
    if (word_id != null)
      maps = await database.query(WORDS_TABLE, columns: [Word.ID_COLUMN, Word.NUMBER_COLUMN], where: "${Word.NAME_COLUMN} = ? AND ${Word.ID_COLUMN} != ?", whereArgs: [word, word_id]);
    else
      maps = await database.query(WORDS_TABLE, columns: [Word.ID_COLUMN, Word.NUMBER_COLUMN], where: "${Word.NAME_COLUMN} = ?", whereArgs: [word]);

    if (maps.isEmpty) return json;

    if (json[Word.NUMBER_COLUMN] != null) {
      int number = json[Word.NUMBER_COLUMN]!;
      if (maps.length == 1)
        await database.update(WORDS_TABLE, {Word.NUMBER_COLUMN: number == 1 ? 2 : 1}, where: "${Word.ID_COLUMN} = ?", whereArgs: [maps.last[Word.ID_COLUMN]]);
      else {
        if (word_id != null)
          await database.rawUpdate(
              "UPDATE ${WORDS_TABLE} SET ${Word.NUMBER_COLUMN} = ${Word.NUMBER_COLUMN} + 1 WHERE ${Word.NAME_COLUMN} = ? AND ${Word.ID_COLUMN} != ? AND ${Word.NUMBER_COLUMN} >= ?",
              [word, word_id, number]);
        else
          await database.rawUpdate("UPDATE ${WORDS_TABLE} SET ${Word.NUMBER_COLUMN} = ${Word.NUMBER_COLUMN} + 1 WHERE ${Word.NAME_COLUMN} = ? AND ${Word.NUMBER_COLUMN} >= ?", [word, number]);
      }
      return json;
    } else {
      int number;
      if (maps.length == 1) {
        number = 1;
        await database.update(WORDS_TABLE, {Word.NUMBER_COLUMN: 1}, where: "${Word.ID_COLUMN} = ?", whereArgs: [maps.last[Word.ID_COLUMN]]);
      } else {
        number = maps.sortedBy<num>((map) => map[Word.NUMBER_COLUMN]).last[Word.NUMBER_COLUMN]!;
      }
      return {...json, Word.NUMBER_COLUMN: number + 1};
    }
  }

  Future _compact_word_numbers(String name, int? number, {DatabaseExecutor? database}) async {
    await db_is_open;
    database = database ?? this.database;
    await database.rawUpdate("UPDATE ${WORDS_TABLE} SET ${Word.NUMBER_COLUMN} = ${Word.NUMBER_COLUMN} - 1 WHERE ${Word.NAME_COLUMN} = ? AND ${Word.NUMBER_COLUMN} > ?", [name, number]);
    await database.update(WORDS_TABLE, {Word.NUMBER_COLUMN: null},
        where: "${Word.NAME_COLUMN} = ? AND (SELECT COUNT(*) FROM ${WORDS_TABLE} WHERE ${Word.NAME_COLUMN} = ?) = 1", whereArgs: [name, name]);
  }

  Future<int> insert_word(Map<String, dynamic> json) async {
    await db_is_open;
    return await database.transaction(
      (txn) async => txn.insert(WORDS_TABLE, await _add_word_number(json, database: txn)),
    );
  }

  Future edit_word(Word original, Map<String, dynamic> updates) async {
    await db_is_open;
    assert(!updates.containsKey(Word.ID_COLUMN));
    return await database.transaction((txn) async {
      if (updates.containsKey(Word.NAME_COLUMN)) updates = await _add_word_number(updates, database: txn, word_id: original.id);
      await txn.update(WORDS_TABLE, updates, where: "${Word.ID_COLUMN} = ?", whereArgs: [original.id]);
      if (updates.containsKey(Word.NAME_COLUMN) && updates[Word.NAME_COLUMN] != original.name) {
        await _compact_word_numbers(original.name, original.number, database: txn);
      }
    });
  }

  Future delete_word(Word word) async {
    await db_is_open;
    return await database.transaction((txn) async {
      await txn.delete(WORDS_TABLE, where: "${Word.ID_COLUMN} = ?", whereArgs: [word.id]);
      if (word.number != null) await _compact_word_numbers(word.name, word.number, database: txn);
    });
  }

  Future<List<Translation>> get_word_translations(int word_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(TRANSLATIONS_TABLE, where: "${Translation.WORD_ID_COLUMN} = ?", whereArgs: [word_id]);
    return maps.map(map_to_translation).toList();
  }

  Future<Translation> get_translation(int variant_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(TRANSLATIONS_TABLE, where: "${Translation.ID_COLUMN} = ?", whereArgs: [variant_id]);
    assert(maps.length == 1);
    return map_to_translation(maps.first);
  }

  static Translation map_to_translation(Map<String, dynamic> map) {
    return Translation(
      id: map[Translation.ID_COLUMN]!,
      word_id: map[Translation.WORD_ID_COLUMN]!,
      translation: map[Translation.TRANSLATION_COLUMN]!,
    );
  }

  Future<int> insert_translation(Map<String, dynamic> json) async {
    await db_is_open;
    assert(json.containsKey(Translation.WORD_ID_COLUMN));
    return await database.insert(TRANSLATIONS_TABLE, json);
  }

  Future edit_translation(int translation_id, Map<String, dynamic> updates) async {
    await db_is_open;
    assert(!updates.containsKey(Translation.ID_COLUMN));
    assert(!updates.containsKey(Translation.WORD_ID_COLUMN));
    await database.update(TRANSLATIONS_TABLE, updates, where: "${Translation.ID_COLUMN} = ?", whereArgs: [translation_id]);
  }

  Future delete_translation(int translation_id) async {
    await db_is_open;
    await database.delete(TRANSLATIONS_TABLE, where: "${Translation.ID_COLUMN} = ?", whereArgs: [translation_id]);
  }
}
