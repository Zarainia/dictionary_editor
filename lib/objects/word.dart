import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/words_cubit.dart';
import 'package:dictionary_editor/objects/base.dart';
import 'package:dictionary_editor/util/utils.dart';

class Translation extends IDIdentifiable {
  static const String ID_COLUMN = "id";
  static const String WORD_ID_COLUMN = "word_id";
  static const String TRANSLATION_COLUMN = "translation";

  final int word_id;
  final String translation;

  const Translation({
    required super.id,
    required this.word_id,
    required this.translation,
  });

  const Translation.initial({required int word_id}) : this(id: -1, word_id: word_id, translation: '');

  @override
  Map<String, dynamic> to_json() {
    return {
      if (id > 0) ID_COLUMN: id,
      WORD_ID_COLUMN: word_id,
      TRANSLATION_COLUMN: translation,
    };
  }

  @override
  Map<String, dynamic> to_edit_json() {
    Map<String, dynamic> json = to_json();
    json.remove(ID_COLUMN);
    json.remove(WORD_ID_COLUMN);
    return json;
  }

  @override
  Future save(BuildContext context, [covariant Translation? original]) async {
    WordsCubit cubit = BlocProvider.of<WordsCubit>(context);
    if (is_new)
      await cubit.insert_translation(this);
    else {
      assert(original != null);
      if (this != original) await cubit.edit_translation(id, to_edit_json());
    }
  }

  Translation copy_with({
    String? translation,
  }) {
    return Translation(
      id: id,
      word_id: word_id,
      translation: translation ?? this.translation,
    );
  }
}

class Word extends IDIdentifiable {
  static const String ID_COLUMN = "id";
  static const String NAME_COLUMN = "name";
  static const String NUMBER_COLUMN = "number";
  static const String PRONUNCIATION_COLUMN = "pronunciation";
  static const String NOTES_COLUMN = "notes";
  static const String ETYMOLOGY_COLUMN = "etymology";
  static const String AUDIO_COLUMN = "audio";

  final String name;
  final int? number;
  final String? pronunciation;
  final String? etymology;
  final String? notes;
  final IList<Translation> translations;
  final Uint8List? audio;

  const Word({
    required super.id,
    required this.name,
    this.number,
    this.pronunciation,
    this.etymology,
    this.notes,
    this.translations = const IListConst([]),
    this.audio,
  });

  const Word.initial() : this(id: -1, name: '');

  Map<int, Translation> get translations_map =>
      Map.fromIterable(translations.where((translation) => !translation.is_new), key: (translation) => (translation as Translation).id, value: (translation) => translation);

  @override
  Map<String, dynamic> to_json() {
    return {
      if (id > 0) ID_COLUMN: id,
      NAME_COLUMN: name,
      NUMBER_COLUMN: number,
      PRONUNCIATION_COLUMN: pronunciation,
      ETYMOLOGY_COLUMN: etymology,
      NOTES_COLUMN: notes,
      AUDIO_COLUMN: audio,
    };
  }

  @override
  Map<String, dynamic> to_edit_json() {
    Map<String, dynamic> json = to_json();
    json.remove(ID_COLUMN);
    return json;
  }

  @override
  Future save(BuildContext context, [covariant Word? original]) async {
    WordsCubit cubit = BlocProvider.of<WordsCubit>(context);
    if (is_new)
      await cubit.insert(this);
    else {
      assert(original != null);
      if (!Serializable.json_shallow_compare(this, original!))
        await cubit.edit(id, to_edit_json());
      else if (translations != original.translations) {
        Map<int, Translation> translations_by_id = translations_map;
        Map<int, Translation> orig_translations = original.translations_map;
        for (int id in translations_by_id.keys) {
          Translation translation = translations_by_id[id]!;
          if (!orig_translations.containsKey(id) || orig_translations[id] != translation) await translation.save(context, orig_translations[id]);
        }

        for (int id in orig_translations.keys) {
          if (!translations_by_id.containsKey(id)) await cubit.delete_translation(id);
        }

        Iterable<Translation> new_translations = translations.where((translation) => translation.is_new);
        for (Translation translation in new_translations) await translation.save(context);
      }
    }
  }

  Word copy_with({
    String? name,
    int? number = -1,
    String? pronunciation = constants.IGNORED_STRING_VALUE,
    String? etymology = constants.IGNORED_STRING_VALUE,
    String? notes = constants.IGNORED_STRING_VALUE,
    IList<Translation>? translations,
    List<int>? audio = constants.IGNORED_UINT8LIST_VALUE,
  }) {
    return Word(
      id: id,
      name: name ?? this.name,
      number: ignore_positive_int_parameter(number, this.number),
      pronunciation: ignore_string_parameter(pronunciation, this.pronunciation),
      etymology: ignore_string_parameter(etymology, this.etymology),
      notes: ignore_string_parameter(notes, this.notes),
      translations: translations ?? this.translations,
      audio: ignore_uint8list_parameter(audio, this.audio),
    );
  }

  @override
  int get hashCode => Object.hashAll([...to_json().entries, ...translations]);

  bool operator ==(Object other) {
    return super == (other) && other is Word && translations == other.translations;
  }
}
