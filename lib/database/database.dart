import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/database/language_database.dart';
import 'package:dictionary_editor/database/letters_database.dart';
import 'package:dictionary_editor/database/pos_database.dart';
import 'package:dictionary_editor/database/words_database.dart';
import 'package:dictionary_editor/objects/letter.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'package:dictionary_editor/objects/word.dart';

bool db_to_bool(int value) => value == 1;

Map<String, dynamic> augment_id(Map<String, dynamic> args, String id_column, int? id) {
  if (id != null) args[id_column] = id;
  return args;
}

class DatabaseManager {
  static const Set<String> TABLES = {"configuration", LettersDatabaseManager.LETTERS_TABLE, PartOfSpeechDatabaseManager.POS_TABLE, "translations", "word_pos", WordsDatabaseManager.WORDS_TABLE};

  static final DatabaseManager _singleton = DatabaseManager._create_singleton();

  DatabaseManager._create_singleton() {
    _first_time_init();
  }

  factory DatabaseManager() => _singleton;

  StreamController<SavepointedDatabase> db_stream_controller = StreamController.broadcast();

  Database? disk_database;
  late Future<void> disk_db_is_open;
  late SavepointedDatabase database;

  Future<void> get db_is_open => disk_db_is_open.then((value) => database.database_ready);

  void _first_time_init() async {
    PlatformName platform = get_platform();
    if (platform.is_desktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await open_new();
    db_stream_controller.sink.add(database);
  }

  Future _open_database(String path) async {
    Future<Database> db = openDatabase(path);
    disk_db_is_open = db.then((value) => value.execute("PRAGMA foreign_keys = true"));
    disk_database = await db;
    database = SavepointedDatabase(disk_database!);
    db_stream_controller.add(database);
  }

  Future close_database() async {
    await db_is_open;
    database.close();
  }

  Future _change_database(String new_path) async {
    await close_database();
    await _open_database(new_path);
  }

  Future change_database(String new_path) async {
    disk_db_is_open = _change_database(new_path);
    await disk_db_is_open;
  }

  Future _create_database() async {
    Future<Database> db = openDatabase("file:new_memory_database?mode=memory&cache=shared", version: constants.DICTIONARY_DB_VERSION, onCreate: _create_database_tables);
    disk_db_is_open = db.then((value) => value.execute("PRAGMA foreign_keys = true"));
    Database memory_database = await db;
    database = SavepointedDatabase(memory_database);
    db_stream_controller.add(database);
  }

  Future open_new() async {
    if (disk_database != null) {
      await close_database();
    }
    disk_database = null;
    await _create_database();
    await db_is_open;
  }

  Future persist() async {
    assert(database.database_stack.length == 1);
    database.commit_savepoint();
  }

  Future save_as_new(String path) async {
    assert(database.database_stack.length == 1);
    Database db = await openDatabase(path, version: constants.DICTIONARY_DB_VERSION, onCreate: _create_database_tables);
    disk_database = db;
    disk_db_is_open = db.execute("PRAGMA foreign_keys = true");
    await disk_db_is_open;
    database.disk_database = db;
    database.commit_savepoint();
  }

  Future _create_database_tables(Database db, int version) async {
    Batch batch = db.batch();
    batch.execute("""
    CREATE TABLE "configuration" (
      ${LanguageDatabaseManager.KEY_COLUMN} TEXT UNIQUE NOT NULL,
      ${LanguageDatabaseManager.VALUE_COLUMN} TEXT,
      PRIMARY KEY(${LanguageDatabaseManager.KEY_COLUMN})
    )
    """);
    batch.execute("""
    CREATE TABLE ${LettersDatabaseManager.LETTERS_TABLE} (
      ${Letter.ID_COLUMN} INTEGER UNIQUE,
      ${Letter.POSITION_COLUMN} INTEGER NOT NULL,
      ${Letter.MAIN_VARIANT_ID_COLUMN} INTEGER,
      ${Letter.SEARCH_NORMALIZATION_COLUMN} TEXT,
      PRIMARY KEY(${Letter.ID_COLUMN} AUTOINCREMENT),
      FOREIGN KEY(${Letter.MAIN_VARIANT_ID_COLUMN}) REFERENCES ${LettersDatabaseManager.VARIANTS_TABLE}(${Variant.ID_COLUMN})
    );
    """);
    batch.execute("""
    CREATE TABLE ${LettersDatabaseManager.VARIANTS_TABLE} (
      ${Variant.ID_COLUMN} INTEGER UNIQUE,
      ${Variant.LETTER_ID_COLUMN} INTEGER NOT NULL,
      ${Variant.LOWERCASE_COLUMN} TEXT NOT NULL,
      ${Variant.UPPERCASE_COLUMN} TEXT,
      ${Variant.ROMANIZATION_COLUMN} TEXT,
      FOREIGN KEY(${Variant.LETTER_ID_COLUMN}) REFERENCES ${LettersDatabaseManager.LETTERS_TABLE}(${Letter.ID_COLUMN}) ON DELETE CASCADE,
      PRIMARY KEY(${Variant.ID_COLUMN} AUTOINCREMENT)
    );
    """);
    batch.execute("""
    CREATE TABLE ${PartOfSpeechDatabaseManager.POS_TABLE} (
      ${PartOfSpeech.ID_COLUMN} INTEGER UNIQUE,
      ${PartOfSpeech.NAME_COLUMN} TEXT NOT NULL,
      PRIMARY KEY(${PartOfSpeech.ID_COLUMN} AUTOINCREMENT)
    )
    """);
    batch.execute("""
    CREATE TABLE ${WordsDatabaseManager.TRANSLATIONS_TABLE} (
      ${Translation.ID_COLUMN} INTEGER UNIQUE,
      ${Translation.WORD_ID_COLUMN} INTEGER NOT NULL,
      ${Translation.TRANSLATION_COLUMN} TEXT NOT NULL,
      PRIMARY KEY(${Translation.ID_COLUMN} AUTOINCREMENT),
      FOREIGN KEY(${Translation.WORD_ID_COLUMN}) REFERENCES ${WordsDatabaseManager.WORDS_TABLE}(${Word.ID_COLUMN}) ON DELETE CASCADE
    )
    """);
    batch.execute("""
    CREATE TABLE ${PartOfSpeechDatabaseManager.WORD_POS_TABLE} (
      ${WordPartOfSpeech.WORD_ID_COLUMN} INTEGER NOT NULL,
      ${WordPartOfSpeech.POS_ID_COLUMN} INTEGER NOT NULL,
      PRIMARY KEY(${WordPartOfSpeech.WORD_ID_COLUMN},${WordPartOfSpeech.POS_ID_COLUMN}),
      FOREIGN KEY(${WordPartOfSpeech.WORD_ID_COLUMN}) REFERENCES ${WordsDatabaseManager.WORDS_TABLE}(${Word.ID_COLUMN}) ON DELETE CASCADE,
      FOREIGN KEY(${WordPartOfSpeech.WORD_ID_COLUMN}) REFERENCES ${PartOfSpeechDatabaseManager.POS_TABLE}(${PartOfSpeech.ID_COLUMN}) ON DELETE CASCADE
    )
    """);
    batch.execute("""
    CREATE TABLE ${WordsDatabaseManager.WORDS_TABLE} (
      ${Word.ID_COLUMN} INTEGER UNIQUE,
      ${Word.NAME_COLUMN} TEXT NOT NULL,
      ${Word.NUMBER_COLUMN} INTEGER,
      ${Word.PRONUNCIATION_COLUMN} TEXT,
      ${Word.NOTES_COLUMN} TEXT,
      ${Word.ETYMOLOGY_COLUMN} TEXT,
      ${Word.AUDIO_COLUMN} BLOB,
      PRIMARY KEY(${Word.ID_COLUMN} AUTOINCREMENT)
    )
    """);
    batch.execute("""
    CREATE INDEX "word_name" ON ${WordsDatabaseManager.WORDS_TABLE} (
      ${Word.NAME_COLUMN}	ASC
    );
    """);
    batch.execute("""
    CREATE UNIQUE INDEX "unique_word_number" ON ${WordsDatabaseManager.WORDS_TABLE} (
      ${Word.NAME_COLUMN}	ASC,
      ${Word.NUMBER_COLUMN}	ASC
    );
    """);
    await batch.commit();
  }
}

class SubDatabaseManager {
  DatabaseManager manager = DatabaseManager();
  late SavepointedDatabase database = manager.database;
  late StreamSubscription<SavepointedDatabase> database_subscription;

  Future<void> get db_is_open => manager.db_is_open;

  void setup_stream() {
    database_subscription = manager.db_stream_controller.stream.listen((db) {
      database = db;
    });
  }

  void close() {
    database_subscription.cancel();
  }
}
