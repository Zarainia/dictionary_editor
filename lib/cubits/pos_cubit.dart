import 'dart:async';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';

import 'package:dictionary_editor/cubits/base_cubit.dart';
import 'package:dictionary_editor/database/pos_database.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'undo_cubit.dart';

class PartOfSpeechInfo {
  final Map<int, PartOfSpeech> pos;
  final List<WordPartOfSpeech> word_pos;
  final Map<int, Set<PartOfSpeech>> pos_by_words;
  final Map<int, Set<WordPartOfSpeech>> words_by_pos;

  PartOfSpeechInfo({this.pos = const {}, this.word_pos = const []})
      : pos_by_words = word_pos.groupSetsBy((wp) => wp.word_id).map((word_id, word_pos) => MapEntry(word_id, word_pos.map((wp) => pos[wp.pos_id]!).toSet())),
        words_by_pos = word_pos.groupSetsBy((wp) => wp.pos_id);
}

class PartsOfSpeechCubit extends IDIdentifiableCubit<PartOfSpeechInfo, PartOfSpeech> {
  String entry_type = "part of speech";

  PartOfSpeechDatabaseManager pos_database = PartOfSpeechDatabaseManager();

  PartsOfSpeechCubit(BuildContext context) : super(context, PartOfSpeechInfo());

  @override
  PartOfSpeech? get_entry(int id) => state.pos[id];

  @override
  String get_entry_name(PartOfSpeech pos) => pos.name;

  Future update() async {
    Map<int, PartOfSpeech> pos = await pos_database.get_pos();
    List<WordPartOfSpeech> word_pos = await pos_database.get_word_pos();
    emit(PartOfSpeechInfo(pos: pos, word_pos: word_pos));
  }

  @override
  Future<PartOfSpeech> insert_(PartOfSpeech pos) async {
    int id = await pos_database.insert_pos(pos.to_json());
    return verify_inserted_entry_(await pos_database.get_pos_single(id), id);
  }

  @override
  Future edit_(int pos_id, Map<String, dynamic> updates) {
    return pos_database.edit_pos(pos_id, updates);
  }

  @override
  Future delete_(int pos_id) {
    return pos_database.delete_pos(pos_id);
  }

  Future delete(int pos_id) async {
    PartOfSpeech entry = get_entry(pos_id)!;
    return undo_cubit.add_action(
      UndoAction(
        name: "Delete ${get_entry_name(entry)}",
        do_func: ([_]) async {
          Set<WordPartOfSpeech> word_pos = state.words_by_pos[pos_id] ?? const {};
          await delete_(pos_id);
          return word_pos;
        },
        undo_func: (word_pos) async {
          await insert_(entry);
          for (WordPartOfSpeech wp in word_pos) await insert_word_pos_(wp);
        },
        callback: update,
      ),
    );
  }

  Future<int> insert_word_pos_(WordPartOfSpeech word_pos) {
    return pos_database.insert_word_pos(word_pos.to_json());
  }

  Future<int> insert_word_pos(WordPartOfSpeech word_pos) {
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Add variant",
        do_func: () => insert_word_pos_(word_pos),
        undo_func: () => _delete_word_pos(word_pos.word_id, word_pos.pos_id),
        callback: update,
      ),
    );
  }

  Future _delete_word_pos(int word_id, int pos_id) {
    return pos_database.delete_word_pos(word_id, pos_id);
  }

  Future delete_word_pos(int word_id, int pos_id) {
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Delete word part of speech",
        do_func: () => _delete_word_pos(word_id, pos_id),
        undo_func: () => insert_word_pos_(WordPartOfSpeech(word_id: word_id, pos_id: pos_id)),
        callback: update,
      ),
    );
  }
}
