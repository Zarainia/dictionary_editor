import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'package:collection/collection.dart';

import 'package:dictionary_editor/cubits/base_cubit.dart';
import 'package:dictionary_editor/database/letters_database.dart';
import 'package:dictionary_editor/objects/letter.dart';
import 'undo_cubit.dart';

class LetterInfo {
  final List<Letter> letters;
  final Map<int, Letter> letters_by_ids;
  final Map<int, Variant> _variants_by_ids;
  final Map<String, String> upper_to_lower;
  final Map<String, String> lower_to_upper;
  final List<String> length_ordered_letters;
  final Map<String, String> normalization;
  final Map<String, int> alphabetical_order;

  static List<Variant> expand_variants(Iterable<Letter> letters) {
    return letters.expand((letter) => letter.all_variants).toList();
  }

  static List<String> expand_forms(Iterable<Variant> variants) {
    return variants.expand((variant) => [variant.uppercase, variant.lowercase]).toList();
  }

  static Map<String, int> generate_alphabetical_order(List<Letter> letters) {
    Map<String, int> order = {};
    for (int i = 0; i < letters.length; i++) {
      for (Variant variant in letters[i].all_variants) {
        order[variant.uppercase] = i;
        order[variant.lowercase] = i;
      }
    }
    return order;
  }

  LetterInfo([this.letters = const []])
      : letters_by_ids = Map.fromIterable(letters, key: (letter) => (letter as Letter).id, value: (letter) => letter as Letter),
        _variants_by_ids = Map.fromIterable(expand_variants(letters), key: (variant) => (variant as Variant).id, value: (variant) => variant),
        upper_to_lower = Map.fromIterable(expand_variants(letters), key: (variant) => (variant as Variant).uppercase, value: (variant) => (variant as Variant).lowercase),
        lower_to_upper = Map.fromIterable(expand_variants(letters), key: (variant) => (variant as Variant).lowercase, value: (variant) => (variant as Variant).uppercase),
        length_ordered_letters = expand_forms(expand_variants(letters)).sortedBy<num>((letter) => letter.length).reversed.toList(),
        normalization = Map.fromEntries(letters.expand((letter) => expand_forms(letter.all_variants).map((form) => MapEntry(form, letter.search_normalization)))),
        alphabetical_order = generate_alphabetical_order(letters);

  List<String> split_word(String word) {
    List<String> letters = [];

    String processing_word = word;
    while (processing_word.isNotEmpty) {
      bool found = false;
      for (String letter in length_ordered_letters) {
        if (processing_word.startsWith(letter)) {
          letters.add(processing_word.substring(0, letter.length));
          processing_word = processing_word.substring(letter.length);
          found = true;
          break;
        }
      }
      if (!found) {
        letters.add(processing_word[0]);
        processing_word = processing_word.substring(1);
      }
    }

    return letters;
  }

  int compare(String a, String b) {
    List<String> split_a = split_word(a);
    List<String> split_b = split_word(b);

    for (int i = 0; i < min(split_a.length, split_b.length); i++) {
      String letter_a = split_a[i];
      String letter_b = split_b[i];
      int? a_index = alphabetical_order[letter_a];
      int? b_index = alphabetical_order[letter_b];

      int result;
      if (a_index == null || b_index == null)
        result = letter_a.compareTo(letter_b);
      else
        result = a_index.compareTo(b_index);
      if (result != 0) return result;
    }

    if (split_a.length > split_b.length)
      return 1;
    else if (split_a.length < split_b.length)
      return -1;
    else
      return 0;
  }

  String upper(String string) {
    return split_word(string).map((char) => lower_to_upper[char] ?? char).join('');
  }

  String lower(String string) {
    return split_word(string).map((char) => upper_to_lower[char] ?? char).join('');
  }

  String normalize(String string) {
    return split_word(string).map((char) => normalization[char] ?? char).join('');
  }
}

class LettersCubit extends IDIdentifiableCubit<LetterInfo, Letter> {
  String entry_type = "letter";

  LettersDatabaseManager letters_database = LettersDatabaseManager();

  LettersCubit(BuildContext context) : super(context, LetterInfo());

  @override
  Letter? get_entry(int id) => state.letters_by_ids[id];

  @override
  String get_entry_name(Letter letter) => letter.uppercase;

  @override
  Future update() async => emit(LetterInfo(await letters_database.get_letters()));

  @override
  Future<Letter> insert_(Letter letter) async {
    int letter_id = await letters_database.insert_letter(letter.to_json(), letter.main_variant.to_json());
    for (Variant variant in letter.other_variants) await _insert_variant(variant, letter_id: letter_id);
    return verify_inserted_entry_(await letters_database.get_letter(letter_id), letter_id);
  }

  @override
  Future edit_(int letter_id, Map<String, dynamic> updates) {
    return letters_database.edit_letter(letter_id, updates);
  }

  @override
  Future delete_(int letter_id) async {
    Letter letter = get_entry(letter_id)!;
    return await letters_database.delete_letter(letter_id, letter.main_variant_id, letter.position);
  }

  Future _reorder(int letter_id, int from, int to) {
    return letters_database.reorder_letter(letter_id, from, to);
  }

  Future reorder(Letter letter, int position) async {
    if (letter.position != position) {
      return await undo_cubit.add_action(
        UndoAction.typeless(
          name: "Reorder ${get_entry_name(letter)}",
          do_func: () => _reorder(letter.id, letter.position, position),
          undo_func: () => _reorder(letter.id, position, letter.position),
          callback: update,
        ),
      );
    }
  }

  Variant? _get_variant(int id) => state._variants_by_ids[id];

  Future<int> _insert_variant(Variant variant, {int? id, int? letter_id}) {
    Map<String, dynamic> json = variant.to_json();
    json = {...json, if (id != null) Variant.ID_COLUMN: id, if (letter_id != null) Variant.LETTER_ID_COLUMN: letter_id};
    return letters_database.insert_variant(json);
  }

  Future<int> insert_variant(Variant variant) {
    return undo_cubit.add_action(
      UndoAction(
        name: "Add variant",
        do_func: ([id]) => _insert_variant(variant, id: id),
        undo_func: (id) => _delete_variant(id),
        callback: update,
      ),
    );
  }

  Future _edit_variant(int variant_id, Map<String, dynamic> updates) {
    return letters_database.edit_variant(variant_id, updates);
  }

  Future edit_variant(int variant_id, Map<String, dynamic> updates) {
    Variant variant = _get_variant(variant_id)!;
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Edit ${variant.uppercase} variant",
        do_func: () => _edit_variant(variant_id, updates),
        undo_func: () => _edit_variant(variant_id, variant.to_edit_json()),
        callback: update,
      ),
    );
  }

  Future _delete_variant(int variant_id) {
    return letters_database.delete_variant(variant_id);
  }

  Future delete_variant(int variant_id) {
    Variant variant = _get_variant(variant_id)!;
    assert(variant_id != get_entry(variant.letter_id)!.main_variant_id);
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Delete variant",
        do_func: () => _delete_variant(variant_id),
        undo_func: () => _insert_variant(variant),
        callback: update,
      ),
    );
  }
}
