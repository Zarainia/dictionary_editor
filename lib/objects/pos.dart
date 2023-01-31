import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/objects/base.dart';

class PartOfSpeech extends IDIdentifiable {
  static const String ID_COLUMN = "id";
  static const String NAME_COLUMN = "name";

  final String name;

  const PartOfSpeech({required super.id, required this.name});

  const PartOfSpeech.initial() : this(id: -1, name: '');

  @override
  Map<String, dynamic> to_json() {
    return {
      if (!is_new) ID_COLUMN: id,
      NAME_COLUMN: name,
    };
  }

  @override
  Map<String, dynamic> to_edit_json() {
    Map<String, dynamic> json = to_json();
    json.remove(ID_COLUMN);
    return json;
  }

  @override
  Future save(BuildContext context, [covariant PartOfSpeech? original]) async {
    PartsOfSpeechCubit cubit = BlocProvider.of<PartsOfSpeechCubit>(context);
    if (is_new)
      await cubit.insert(this);
    else {
      assert(original != null);
      if (this != original) await cubit.edit(id, to_edit_json());
    }
  }

  PartOfSpeech copy_with({
    String? name,
  }) {
    return PartOfSpeech(
      id: id,
      name: name ?? this.name,
    );
  }
}

class WordPartOfSpeech extends DatabaseItem {
  static const String WORD_ID_COLUMN = "word_id";
  static const String POS_ID_COLUMN = "pos_id";

  final bool is_new;
  final int word_id;
  final int pos_id;

  const WordPartOfSpeech({required this.word_id, required this.pos_id}) : is_new = false;

  const WordPartOfSpeech.initial({required this.word_id, required this.pos_id}) : is_new = true;

  @override
  Map<String, dynamic> to_json() {
    return {
      WORD_ID_COLUMN: word_id,
      POS_ID_COLUMN: pos_id,
    };
  }

  @override
  Map<String, dynamic> to_edit_json() {
    throw UnimplementedError();
  }

  @override
  Future save(BuildContext context, [covariant PartOfSpeech? original]) async {
    PartsOfSpeechCubit cubit = BlocProvider.of<PartsOfSpeechCubit>(context);
    if (is_new) await cubit.insert_word_pos(this);
  }
}
