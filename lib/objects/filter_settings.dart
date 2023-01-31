import 'dart:async';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/objects/word.dart';
import 'package:dictionary_editor/util/utils.dart';

class IncludesFieldFilter {
  final bool? number;
  final bool? pronunciation;
  final bool? etymology;
  final bool? notes;
  final bool? translations;
  final bool? audio;

  const IncludesFieldFilter({
    this.number,
    this.pronunciation,
    this.etymology,
    this.notes,
    this.translations,
    this.audio,
  });

  bool match(Word word) {
    bool matches = true;
    if (number != null) matches &= number == (word.number != null);
    if (pronunciation != null) matches &= pronunciation == (word.pronunciation != null);
    if (etymology != null) matches &= etymology == (word.etymology != null);
    if (notes != null) matches &= notes == (word.notes != null);
    if (translations != null) matches &= translations == (word.translations.isNotEmpty);
    if (audio != null) matches &= audio == (word.audio != null);
    return matches;
  }

  IncludesFieldFilter copy_with({
    FutureOr<bool?> number,
    FutureOr<bool?> pronunciation,
    FutureOr<bool?> etymology,
    FutureOr<bool?> notes,
    FutureOr<bool?> translations,
    FutureOr<bool?> audio,
  }) {
    return IncludesFieldFilter(
      number: ignore_bool_parameter(number, this.number),
      pronunciation: ignore_bool_parameter(pronunciation, this.pronunciation),
      etymology: ignore_bool_parameter(etymology, this.etymology),
      notes: ignore_bool_parameter(notes, this.notes),
      translations: ignore_bool_parameter(translations, this.translations),
      audio: ignore_bool_parameter(audio, this.audio),
    );
  }
}

class FilterSettings {
  final String? conlang_search_string;
  final String? baselang_search_string;
  final Set<int> pos_ids;
  final IncludesFieldFilter included_fields;
  final String? pronunciation_search_string;
  final String? etymology_search_string;
  final String? notes_search_string;

  const FilterSettings({
    this.conlang_search_string,
    this.baselang_search_string,
    this.pos_ids = const {},
    this.included_fields = const IncludesFieldFilter(),
    this.pronunciation_search_string,
    this.etymology_search_string,
    this.notes_search_string,
  });

  bool match({required Word word, required Set<PartOfSpeech> pos, required LetterInfo letter_info, required Settings settings}) {
    bool matches = true;
    if (conlang_search_string != null && conlang_search_string!.isNotEmpty) matches &= settings.get_conlang_matches(word.name, conlang_search_string!, letter_info).isNotEmpty;
    if (baselang_search_string != null && baselang_search_string!.isNotEmpty)
      matches &= word.translations.any(
        (translation) => settings.get_baselang_matches(translation.translation, baselang_search_string!).isNotEmpty,
      );
    if (included_fields.pronunciation == true && pronunciation_search_string != null && pronunciation_search_string!.isNotEmpty && word.pronunciation != null)
      matches &= settings.get_baselang_matches(word.pronunciation!, pronunciation_search_string!).isNotEmpty;
    if (included_fields.etymology == true && etymology_search_string != null && etymology_search_string!.isNotEmpty && word.etymology != null)
      matches &= settings.get_baselang_matches(word.etymology!, etymology_search_string!).isNotEmpty;
    if (included_fields.notes == true && notes_search_string != null && notes_search_string!.isNotEmpty && word.notes != null)
      matches &= settings.get_baselang_matches(word.notes!, notes_search_string!).isNotEmpty;
    if (pos_ids.isNotEmpty) matches &= pos.map((pos) => pos.id).toSet().intersection(pos_ids).isNotEmpty;
    matches &= included_fields.match(word);
    return matches;
  }

  FilterSettings copy_with({
    String? conlang_search_string = constants.IGNORED_STRING_VALUE,
    String? baselang_search_string = constants.IGNORED_STRING_VALUE,
    Set<int>? pos_ids,
    IncludesFieldFilter? included_fields,
    String? pronunciation_search_string = constants.IGNORED_STRING_VALUE,
    String? etymology_search_string = constants.IGNORED_STRING_VALUE,
    String? notes_search_string = constants.IGNORED_STRING_VALUE,
  }) {
    return FilterSettings(
      conlang_search_string: ignore_string_parameter(conlang_search_string, this.conlang_search_string),
      baselang_search_string: ignore_string_parameter(baselang_search_string, this.baselang_search_string),
      pos_ids: pos_ids ?? this.pos_ids,
      included_fields: included_fields ?? this.included_fields,
      pronunciation_search_string: ignore_string_parameter(pronunciation_search_string, this.pronunciation_search_string),
      etymology_search_string: ignore_string_parameter(etymology_search_string, this.etymology_search_string),
      notes_search_string: ignore_string_parameter(notes_search_string, this.notes_search_string),
    );
  }
}
