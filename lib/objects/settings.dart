import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/letters_cubit.dart';

class Settings {
  static const String THEME_SETTING = "theme";
  static const String PREVIOUS_FILE_SETTING = "previous_file";
  static const String EDIT_PANEL_WIDTH_SETTING = "edit_panel_width";
  static const String REGEX_SEARCH_SETTING = "regex_search";
  static const String BASELANG_CASE_SENSITIVE_SEARCH_SETTING = "baselang_case_sensitive_search";
  static const String CONLANG_NORMALIZED_SEARCH_SETTING = "conlang_normalized_search";
  static const String CONLANG_CASE_SENSITIVE_SEARCH_SETTING = "conlang_case_sensitive_search";

  final String theme;
  final String? previous_file;
  final double edit_panel_width;

  final bool regex_search;
  final bool baselang_case_sensitive_search;
  final bool conlang_normalized_search;
  final bool conlang_case_sensitive_search;

  const Settings({
    String? theme,
    this.previous_file,
    double? edit_panel_width,
    bool? regex_search,
    bool? baselang_case_sensitive_search,
    bool? conlang_normalized_search,
    bool? conlang_case_sensitive_search,
  })  : theme = theme ?? "light",
        edit_panel_width = edit_panel_width ?? constants.DEFAULT_EDIT_PANEL_WIDTH,
        regex_search = regex_search ?? false,
        baselang_case_sensitive_search = baselang_case_sensitive_search ?? false,
        conlang_normalized_search = conlang_normalized_search ?? true,
        conlang_case_sensitive_search = conlang_case_sensitive_search ?? false;

  String _fold_conlang_case(String string, LetterInfo letter_info) {
    if (conlang_normalized_search)
      string = letter_info.normalize(string);
    else if (!conlang_case_sensitive_search) string = letter_info.lower(string);
    return string;
  }

  String _fold_baselang_case(String string) {
    if (!baselang_case_sensitive_search) string = string.toLowerCase();
    return string;
  }

  List<Match> get_conlang_matches(String text, String search_string, LetterInfo letter_info) {
    if (search_string.isEmpty) return [];
    text = _fold_conlang_case(text, letter_info);
    if (!regex_search) search_string = RegExp.escape(_fold_conlang_case(search_string, letter_info));
    RegExp regex = RegExp(search_string, multiLine: true);
    return regex.allMatches(text).toList();
  }

  List<Match> get_baselang_matches(String text, String search_string) {
    if (search_string.isEmpty) return [];
    text = _fold_baselang_case(text);
    if (!regex_search) search_string = RegExp.escape(_fold_baselang_case(search_string));
    RegExp regex = RegExp(search_string, multiLine: true);
    return regex.allMatches(text).toList();
  }
}
