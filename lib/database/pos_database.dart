import 'package:dictionary_editor/database/database.dart';
import 'package:dictionary_editor/objects/pos.dart';

class PartOfSpeechDatabaseManager extends SubDatabaseManager {
  static const String POS_TABLE = "pos";
  static const String WORD_POS_TABLE = "word_pos";

  static final PartOfSpeechDatabaseManager _singleton = PartOfSpeechDatabaseManager._create_singleton();

  PartOfSpeechDatabaseManager._create_singleton() {
    setup_stream();
  }

  factory PartOfSpeechDatabaseManager() => _singleton;

  Future<Map<int, PartOfSpeech>> get_pos() async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(POS_TABLE);
    return Map.fromIterable(maps, key: (map) => map[PartOfSpeech.ID_COLUMN]!, value: (map) => map_to_pos(map));
  }

  Future<PartOfSpeech> get_pos_single(int pos_id) async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(POS_TABLE, where: "${PartOfSpeech.ID_COLUMN} = ?", whereArgs: [pos_id]);
    assert(maps.length == 1);
    return map_to_pos(maps.first);
  }

  static PartOfSpeech map_to_pos(Map<String, dynamic> map) {
    return PartOfSpeech(
      id: map[PartOfSpeech.ID_COLUMN]!,
      name: map[PartOfSpeech.NAME_COLUMN]!,
    );
  }

  Future<int> insert_pos(Map<String, dynamic> json) async {
    await db_is_open;
    return await database.insert(POS_TABLE, json);
  }

  Future edit_pos(int pos_id, Map<String, dynamic> updates) async {
    await db_is_open;
    assert(!updates.containsKey(PartOfSpeech.ID_COLUMN));
    await database.update(POS_TABLE, updates, where: "${PartOfSpeech.ID_COLUMN} = ?", whereArgs: [pos_id]);
  }

  Future delete_pos(int pos_id) async {
    await db_is_open;
    await database.delete(POS_TABLE, where: "${PartOfSpeech.ID_COLUMN} = ?", whereArgs: [pos_id]);
  }

  Future<List<WordPartOfSpeech>> get_word_pos() async {
    await db_is_open;
    List<Map<String, dynamic>> maps = await database.query(WORD_POS_TABLE);
    return maps.map(map_to_word_pos).toList();
  }

  static WordPartOfSpeech map_to_word_pos(Map<String, dynamic> map) {
    return WordPartOfSpeech(
      word_id: map[WordPartOfSpeech.WORD_ID_COLUMN]!,
      pos_id: map[WordPartOfSpeech.POS_ID_COLUMN]!,
    );
  }

  Future<int> insert_word_pos(Map<String, dynamic> json) async {
    await db_is_open;
    return await database.insert(WORD_POS_TABLE, json);
  }

  Future delete_word_pos(int word_id, int pos_id) async {
    await db_is_open;
    await database.delete(WORD_POS_TABLE, where: "${WordPartOfSpeech.WORD_ID_COLUMN} = ? AND ${WordPartOfSpeech.POS_ID_COLUMN} = ?", whereArgs: [word_id, pos_id]);
  }
}
