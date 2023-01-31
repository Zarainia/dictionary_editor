import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/database/database.dart';
import 'package:dictionary_editor/objects/letter.dart';

class LettersDatabaseManager extends SubDatabaseManager {
  static const String LETTERS_TABLE = "letters";
  static const String VARIANTS_TABLE = "variants";

  static final LettersDatabaseManager _singleton = LettersDatabaseManager._create_singleton();

  LettersDatabaseManager._create_singleton() {
    setup_stream();
  }

  factory LettersDatabaseManager() => _singleton;

  Future<List<Letter>> get_letters() async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(LETTERS_TABLE);
    return (await Future.wait(maps.map(_resolve_letter))).sortedBy((letter) => letter.position as num).toList();
  }

  Future<Letter> get_letter(int letter_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(LETTERS_TABLE, where: "${Letter.ID_COLUMN} = ?", whereArgs: [letter_id]);
    assert(maps.length == 1);
    return await _resolve_letter(maps.first);
  }

  Future<Letter> _resolve_letter(Map<String, dynamic> map) async {
    return map_to_letter(
      map,
      variants: await get_letter_variants(map[Letter.ID_COLUMN]!),
    );
  }

  static Letter map_to_letter(Map<String, dynamic> map, {required List<Variant> variants}) {
    Variant main_variant = variants.firstWhere((variant) => variant.id == map[Letter.MAIN_VARIANT_ID_COLUMN]!);

    return Letter(
      id: map[Letter.ID_COLUMN]!,
      position: map[Letter.POSITION_COLUMN]!,
      main_variant_id: map[Letter.MAIN_VARIANT_ID_COLUMN]!,
      main_variant: main_variant,
      other_variants: variants.where((variant) => variant.id != main_variant.id).toIList(),
      search_normalization: map[Letter.SEARCH_NORMALIZATION_COLUMN],
    );
  }

  Future _make_position_gap(int position, {DatabaseExecutor? database}) async {
    await db_is_open;
    database = database ?? this.database;
    return await database.rawUpdate("UPDATE ${LETTERS_TABLE} SET ${Letter.POSITION_COLUMN} = ${Letter.POSITION_COLUMN} + 1 WHERE ${Letter.POSITION_COLUMN} >= ?", [position]);
  }

  Future _remove_position_gap(int position, {DatabaseExecutor? database}) async {
    await db_is_open;
    database = database ?? this.database;
    return await database.rawUpdate("UPDATE ${LETTERS_TABLE} SET ${Letter.POSITION_COLUMN} = ${Letter.POSITION_COLUMN} - 1 WHERE ${Letter.POSITION_COLUMN} >= ?", [position]);
  }

  Future<int> insert_letter(Map<String, dynamic> letter_json, Map<String, dynamic> main_variant_json) async {
    await db_is_open;
    return await database.transaction((txn) async {
      await _make_position_gap(letter_json[Letter.POSITION_COLUMN]!, database: txn);
      int letter_id = await txn.insert(LETTERS_TABLE, letter_json);
      main_variant_json = {...main_variant_json, Variant.LETTER_ID_COLUMN: letter_id};
      int variant_id = await insert_variant(main_variant_json, database: txn);
      await txn.update(LETTERS_TABLE, {Letter.MAIN_VARIANT_ID_COLUMN: variant_id}, where: "${Letter.ID_COLUMN} = ?", whereArgs: [letter_id]);
      return letter_id;
    });
  }

  Future edit_letter(int letter_id, Map<String, dynamic> updates) async {
    await db_is_open;
    assert(!updates.containsKey(Letter.ID_COLUMN));
    assert(!updates.containsKey(Letter.POSITION_COLUMN));
    assert(!updates.containsKey(Letter.MAIN_VARIANT_ID_COLUMN));
    await database.update(LETTERS_TABLE, updates, where: "${Letter.ID_COLUMN} = ?", whereArgs: [letter_id]);
  }

  Future reorder_letter(int letter_id, int from, int to) async {
    await db_is_open;
    database.transaction((txn) async {
      if (from == to)
        return;
      else if (to > from)
        await txn.rawUpdate(
            "UPDATE ${LETTERS_TABLE} SET ${Letter.POSITION_COLUMN} = ${Letter.POSITION_COLUMN} - 1 WHERE ${Letter.POSITION_COLUMN} > ? AND ${Letter.POSITION_COLUMN} <= ? AND ${Letter.ID_COLUMN} != ?",
            [from, to, letter_id]);
      else
        await txn.rawUpdate(
            "UPDATE ${LETTERS_TABLE} SET ${Letter.POSITION_COLUMN} = ${Letter.POSITION_COLUMN} + 1 WHERE ${Letter.POSITION_COLUMN} >= ? AND ${Letter.POSITION_COLUMN} < ? AND ${Letter.ID_COLUMN} != ?",
            [to, from, letter_id]);
      await txn.update(LETTERS_TABLE, {Letter.POSITION_COLUMN: to}, where: "${Letter.ID_COLUMN} = ?", whereArgs: [letter_id]);
    });
  }

  Future delete_letter(int letter_id, int main_variant_id, int position) async {
    await db_is_open;
    database.transaction((txn) async {
      await delete_variant(main_variant_id, database: txn);
      await txn.delete(LETTERS_TABLE, where: "${Letter.ID_COLUMN} = ?", whereArgs: [letter_id]);
      await _remove_position_gap(position, database: txn);
    });
  }

  Future<List<Variant>> get_letter_variants(int letter_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(VARIANTS_TABLE, where: "${Variant.LETTER_ID_COLUMN} = ?", whereArgs: [letter_id]);
    return maps.map(map_to_variant).toList();
  }

  Future<Variant> get_variant(int variant_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(VARIANTS_TABLE, where: "${Variant.ID_COLUMN} = ?", whereArgs: [variant_id]);
    assert(maps.length == 1);
    return map_to_variant(maps.first);
  }

  static Variant map_to_variant(Map<String, dynamic> map) {
    return Variant(
      id: map[Variant.ID_COLUMN]!,
      letter_id: map[Variant.LETTER_ID_COLUMN]!,
      lowercase: map[Variant.LOWERCASE_COLUMN]!,
      uppercase: empty_null(map[Variant.UPPERCASE_COLUMN]),
      romanization: empty_null(map[Variant.ROMANIZATION_COLUMN]),
    );
  }

  Future<int> insert_variant(Map<String, dynamic> json, {DatabaseExecutor? database}) async {
    await db_is_open;
    database = database ?? this.database;
    assert(json.containsKey(Variant.LETTER_ID_COLUMN));
    return await database.insert(VARIANTS_TABLE, json);
  }

  Future edit_variant(int variant_id, Map<String, dynamic> updates) async {
    await db_is_open;
    assert(!updates.containsKey(Variant.ID_COLUMN));
    assert(!updates.containsKey(Variant.LETTER_ID_COLUMN));
    await database.update(VARIANTS_TABLE, updates, where: "${Variant.ID_COLUMN} = ?", whereArgs: [variant_id]);
  }

  Future delete_variant(int variant_id, {DatabaseExecutor? database}) async {
    await db_is_open;
    database = database ?? this.database;
    await database.delete(VARIANTS_TABLE, where: "${Variant.ID_COLUMN} = ?", whereArgs: [variant_id]);
  }
}
