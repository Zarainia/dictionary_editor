import 'dart:async';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/filter_settings_cubit.dart';
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/cubits/words_cubit.dart';
import 'package:dictionary_editor/objects/filter_settings.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/objects/word.dart';

class WordListCubit extends Cubit<List<Word>> {
  WordsCubit words_cubit;
  PartsOfSpeechCubit pos_cubit;
  LettersCubit letters_cubit;
  SettingsCubit settings_cubit;
  FilterSettingsCubit filter_settings_cubit;

  late StreamSubscription<Map<int, Word>> words_subscription;
  late StreamSubscription<PartOfSpeechInfo> pos_subscription;
  late StreamSubscription<LetterInfo> letters_subscription;
  late StreamSubscription<Settings> settings_subscription;
  late StreamSubscription<FilterSettings> filter_settings_subscription;

  WordListCubit(BuildContext context)
      : words_cubit = BlocProvider.of<WordsCubit>(context),
        pos_cubit = BlocProvider.of<PartsOfSpeechCubit>(context),
        letters_cubit = BlocProvider.of<LettersCubit>(context),
        settings_cubit = BlocProvider.of<SettingsCubit>(context),
        filter_settings_cubit = BlocProvider.of<FilterSettingsCubit>(context),
        super(const []) {
    words_subscription = words_cubit.stream.listen((event) => filter_words());
    pos_subscription = pos_cubit.stream.listen((event) => filter_words());
    letters_subscription = letters_cubit.stream.listen((event) => filter_words());
    settings_subscription = settings_cubit.stream.listen((event) => filter_words());
    filter_settings_subscription = filter_settings_cubit.stream.listen((event) => filter_words());
  }

  void filter_words() {
    LetterInfo letter_info = letters_cubit.state;
    List<Word> words = words_cubit.state.values
        .where(
          (word) => filter_settings_cubit.state.match(
            word: word,
            pos: pos_cubit.state.pos_by_words[word.id] ?? {},
            letter_info: letter_info,
            settings: settings_cubit.state,
          ),
        )
        .toList()
        .sorted(
          letter_info.compare.compareBy((Word word) => word.name).then(
                (Word a, Word b) => compare_null(a.number, b.number, (x, y) => x.compareTo(y)),
              ),
        );
    emit(words);
  }
}
