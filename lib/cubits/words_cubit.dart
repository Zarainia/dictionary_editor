import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/cubits/base_cubit.dart';
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/cubits/undo_cubit.dart';
import 'package:dictionary_editor/database/words_database.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'package:dictionary_editor/objects/word.dart';

class WordsCubit extends IDIdentifiableCubit<Map<int, Word>, Word> {
  String entry_type = "word";

  WordsDatabaseManager words_database = WordsDatabaseManager();

  Map<int, Translation> translations = {};

  WordsCubit(BuildContext context) : super(context, {});

  @override
  Word? get_entry(int id) => state[id];

  @override
  String get_entry_name(Word pos) => pos.name;

  Future update() async {
    Map<int, Word> words = await words_database.get_words();
    translations = Map.fromEntries(words.values.expand((word) => word.translations).map((translation) => MapEntry(translation.id, translation)));
    emit(words);
  }

  @override
  Future<Word> insert_(Word word) async {
    int id = await words_database.insert_word(word.to_json());
    for (Translation translation in word.translations) await _insert_translation(translation, word_id: id);
    return verify_inserted_entry_(await words_database.get_word(id), id);
  }

  @override
  Future edit_(int word_id, Map<String, dynamic> updates) {
    return words_database.edit_word(get_entry(word_id)!, updates);
  }

  @override
  Future delete_(int word_id) {
    return words_database.delete_word(get_entry(word_id)!);
  }

  Future delete(int word_id) async {
    Word entry = get_entry(word_id)!;
    PartsOfSpeechCubit pos_cubit = BlocProvider.of<PartsOfSpeechCubit>(context);
    return undo_cubit.add_action(
      UndoAction(
        name: "Delete ${get_entry_name(entry)}",
        do_func: ([_]) async {
          Set<PartOfSpeech> pos = pos_cubit.state.pos_by_words[word_id] ?? const {};
          await delete_(word_id);
          return pos;
        },
        undo_func: (word_pos) async {
          await insert_(entry);
          for (PartOfSpeech pos in word_pos) await pos_cubit.insert_word_pos_(WordPartOfSpeech(word_id: word_id, pos_id: pos.id));
        },
        callback: update,
      ),
    );
  }

  Translation? _get_translation(int id) => translations[id];

  Future<int> _insert_translation(Translation translation, {int? id, int? word_id}) {
    Map<String, dynamic> json = translation.to_json();
    json = {...json, if (id != null) Translation.ID_COLUMN: id, if (word_id != null) Translation.WORD_ID_COLUMN: word_id};
    return words_database.insert_translation(json);
  }

  Future<int> insert_translation(Translation translation) {
    return undo_cubit.add_action(
      UndoAction(
        name: "Add translation",
        do_func: ([id]) => _insert_translation(translation, id: id),
        undo_func: (id) => _delete_translation(id),
        callback: update,
      ),
    );
  }

  Future _edit_translation(int translation_id, Map<String, dynamic> updates) {
    return words_database.edit_translation(translation_id, updates);
  }

  Future edit_translation(int translation_id, Map<String, dynamic> updates) {
    Translation translation = _get_translation(translation_id)!;
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Edit ${translation.translation}",
        do_func: () => _edit_translation(translation_id, updates),
        undo_func: () => _edit_translation(translation_id, translation.to_edit_json()),
        callback: update,
      ),
    );
  }

  Future _delete_translation(int translation_id) {
    return words_database.delete_translation(translation_id);
  }

  Future delete_translation(int translation_id) {
    Translation translation = _get_translation(translation_id)!;
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Delete translation",
        do_func: () => _delete_translation(translation_id),
        undo_func: () => _insert_translation(translation),
        callback: update,
      ),
    );
  }
}
