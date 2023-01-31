import 'package:flutter/material.dart';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/objects/base.dart';
import 'package:dictionary_editor/util/utils.dart';

class Variant extends IDIdentifiable {
  static const String ID_COLUMN = "id";
  static const String LETTER_ID_COLUMN = "letter_id";
  static const String LOWERCASE_COLUMN = "lowercase";
  static const String UPPERCASE_COLUMN = "uppercase";
  static const String ROMANIZATION_COLUMN = "romanization";

  final int letter_id;
  final String lowercase;
  final String? actual_uppercase;
  final String? romanization;

  const Variant({
    required super.id,
    required this.letter_id,
    required this.lowercase,
    String? uppercase,
    this.romanization,
  }) : actual_uppercase = uppercase;

  const Variant.initial({required int letter_id}) : this(id: -1, letter_id: letter_id, lowercase: '');

  String get uppercase => actual_uppercase ?? lowercase;

  @override
  Map<String, dynamic> to_json() {
    return {
      if (!is_new) ID_COLUMN: id,
      LETTER_ID_COLUMN: letter_id,
      LOWERCASE_COLUMN: lowercase,
      UPPERCASE_COLUMN: actual_uppercase,
      ROMANIZATION_COLUMN: romanization,
    };
  }

  @override
  Map<String, dynamic> to_edit_json() {
    Map<String, dynamic> json = to_json();
    json.remove(ID_COLUMN);
    json.remove(LETTER_ID_COLUMN);
    return json;
  }

  @override
  Future save(BuildContext context, [covariant Variant? original]) async {
    LettersCubit cubit = BlocProvider.of<LettersCubit>(context);
    if (is_new)
      await cubit.insert_variant(this);
    else {
      assert(original != null);
      if (this != original) await cubit.edit_variant(id, to_edit_json());
    }
  }

  Variant copy_with({
    String? lowercase,
    String? uppercase = constants.IGNORED_STRING_VALUE,
    String? romanization = constants.IGNORED_STRING_VALUE,
  }) {
    return Variant(
      id: id,
      letter_id: letter_id,
      lowercase: lowercase ?? this.lowercase,
      uppercase: ignore_string_parameter(uppercase, actual_uppercase),
      romanization: ignore_string_parameter(romanization, this.romanization),
    );
  }
}

class Letter extends IDIdentifiable {
  static const String ID_COLUMN = "id";
  static const String POSITION_COLUMN = "position";
  static const String MAIN_VARIANT_ID_COLUMN = "main_variant_id";
  static const String SEARCH_NORMALIZATION_COLUMN = "search_normalization";

  final int main_variant_id;
  final int position;
  final String? actual_search_normalization;

  final Variant main_variant;
  final IList<Variant> other_variants;

  const Letter({
    required super.id,
    required this.position,
    required this.main_variant_id,
    required this.main_variant,
    this.other_variants = const IListConst([]),
    String? search_normalization,
  }) : actual_search_normalization = search_normalization;

  const Letter.initial({required int position}) : this(id: -1, position: position, main_variant_id: -1, main_variant: const Variant.initial(letter_id: -1));

  String get uppercase => main_variant.uppercase;

  String get lowercase => main_variant.lowercase;

  String get search_normalization => actual_search_normalization ?? lowercase;

  IList<Variant> get all_variants => [main_variant].lock + other_variants;

  Map<int, Variant> get variants_map => Map.fromIterable(all_variants.where((variant) => !variant.is_new), key: (variant) => (variant as Variant).id, value: (variant) => variant);

  @override
  Map<String, dynamic> to_json() {
    return {
      if (!is_new) ID_COLUMN: id,
      POSITION_COLUMN: position,
      MAIN_VARIANT_ID_COLUMN: main_variant_id,
      SEARCH_NORMALIZATION_COLUMN: actual_search_normalization,
    };
  }

  @override
  Map<String, dynamic> to_edit_json() {
    Map<String, dynamic> json = to_json();
    json.remove(ID_COLUMN);
    json.remove(POSITION_COLUMN);
    json.remove(MAIN_VARIANT_ID_COLUMN);
    return json;
  }

  @override
  Future save(BuildContext context, [covariant Letter? original]) async {
    LettersCubit cubit = BlocProvider.of<LettersCubit>(context);
    if (is_new)
      await cubit.insert(this);
    else {
      assert(original != null);
      if (!Serializable.json_shallow_compare(this, original!))
        await cubit.edit(id, to_edit_json());
      else if (all_variants != original.all_variants) {
        Map<int, Variant> variants = variants_map;
        Map<int, Variant> orig_variants = original.variants_map;
        for (int id in variants.keys) {
          Variant variant = variants[id]!;
          if (!orig_variants.containsKey(id) || orig_variants[id] != variant) await variant.save(context, orig_variants[id]);
        }

        for (int id in orig_variants.keys) {
          if (!variants.containsKey(id)) await cubit.delete_variant(id);
        }

        Iterable<Variant> new_variants = all_variants.where((variant) => variant.is_new);
        for (Variant variant in new_variants) await variant.save(context);
      }
    }
  }

  Letter copy_with({
    int? position,
    Variant? main_variant,
    IList<Variant>? other_variants,
    String? search_normalization = constants.IGNORED_STRING_VALUE,
  }) {
    return Letter(
      id: id,
      position: position ?? this.position,
      main_variant_id: main_variant_id,
      main_variant: main_variant ?? this.main_variant,
      other_variants: other_variants ?? this.other_variants,
      search_normalization: ignore_string_parameter(search_normalization, actual_search_normalization),
    );
  }

  @override
  int get hashCode => Object.hashAll([...to_json().entries, ...all_variants]);

  bool operator ==(Object other) {
    return super == (other) && other is Letter && all_variants == other.all_variants;
  }
}
