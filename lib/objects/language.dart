import 'package:dictionary_editor/objects/base.dart';

class Language implements Serializable {
  static const String CONLANG_NAME_SETTING = "conlang_name";
  static const String BASELANG_NAME_SETTING = "baselang_name";
  static const String CONLANG_FONT_SETTING = "conlang_font";
  static const String BASE_CONLANG_FONT_SIZE_SETTING = "base_conlang_font_size";
  static const String BASELANG_FONT_SETTING = "baselang_font";
  static const String BASE_BASELANG_FONT_SIZE_SETTING = "base_baselang_font_size";

  final String conlang_name;
  final String baselang_name;
  final String? conlang_font;
  final double? base_conlang_font_size;
  final String? baselang_font;
  final double? base_baselang_font_size;

  const Language({
    String? conlang_name,
    String? baselang_name,
    this.conlang_font,
    this.base_conlang_font_size,
    this.baselang_font,
    this.base_baselang_font_size,
  })  : conlang_name = conlang_name ?? "Conlang",
        baselang_name = baselang_name ?? "English";

  @override
  Map<String, dynamic> to_json() {
    return {
      CONLANG_NAME_SETTING: conlang_name,
      BASELANG_NAME_SETTING: baselang_name,
      CONLANG_FONT_SETTING: conlang_font,
      BASE_CONLANG_FONT_SIZE_SETTING: base_conlang_font_size,
      BASELANG_FONT_SETTING: baselang_font,
      BASE_BASELANG_FONT_SIZE_SETTING: base_baselang_font_size,
    };
  }
}
