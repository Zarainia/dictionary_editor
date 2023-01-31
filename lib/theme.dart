import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/language_cubit.dart';
import 'package:dictionary_editor/objects/language.dart';

final Color DEFAULT_PRIMARY_COLOUR = Colors.blueGrey[500]!;
final Color DEFAULT_ACCENT_COLOUR = Colors.deepOrangeAccent[400]!;

class ThemeColours extends ZarainiaTheme {
  static const double DEFAULT_FONT_SIZE = 10;

  Widget Function({required Widget Function(BuildContext) builder, required String theme, Color? background_colour, required Color? primary_colour, required Color? secondary_colour}) provider =
      AppThemeProvider.new;

  String? CONLANG_FONT;
  double BASE_CONLANG_FONT_SIZE = DEFAULT_FONT_SIZE;
  TextStyle CONLANG_STYLE = const TextStyle();
  String? BASELANG_FONT;
  double BASE_BASELANG_FONT_SIZE = DEFAULT_FONT_SIZE;
  TextStyle BASELANG_STYLE = const TextStyle();

  TextStyle LARGER_CONLANG_STYLE = const TextStyle();
  TextStyle LARGER_BASELANG_STYLE = const TextStyle();
  TextStyle APPBAR_CONLANG_STYLE = const TextStyle();

  TextStyle WORD_STYLE = const TextStyle();
  TextStyle WORD_NUMBER_STYLE = const TextStyle();
  TextStyle POS_STYLE = const TextStyle();
  TextStyle PRONUNCIATION_STYLE = const TextStyle();
  TextStyle TRANSLATION_STYLE = const TextStyle();
  TextStyle ETYMOLOGY_STYLE = const TextStyle();
  TextStyle NOTES_STYLE = const TextStyle();

  ThemeColours({
    required super.theme_name,
    super.background_colour,
    Color? primary_colour,
    Color? secondary_colour,
    required super.platform,
    required super.localizations,
    Language? language,
  }) : super(
          primary_colour: primary_colour ?? DEFAULT_PRIMARY_COLOUR,
          secondary_colour: secondary_colour ?? DEFAULT_ACCENT_COLOUR,
          default_primary_colour: DEFAULT_PRIMARY_COLOUR,
          default_accent_colour: DEFAULT_ACCENT_COLOUR,
          default_additional_colour: DEFAULT_PRIMARY_COLOUR,
        ) {
    BORDER_COLOUR = Color.lerp(ZarainiaTheme.make_text_colour(DEFAULT_PRIMARY_COLOUR, BASE_TEXT_COLOUR.brightness), null, 0.65)!;
    DIVIDER_COLOUR = BORDER_COLOUR;
    SEARCH_HIGHLIGHT_STYLE = TextStyle(backgroundColor: Color.lerp(ACCENT_COLOUR, null, is_dark ? 0.6 : 0.8));

    SMALL_HEADER_STYLE = SMALL_HEADER_STYLE.copyWith(fontSize: 22, fontWeight: FontWeight.w500);

    if (language != null) {
      CONLANG_FONT = language.conlang_font;
      BASE_CONLANG_FONT_SIZE = language.base_conlang_font_size ?? DEFAULT_FONT_SIZE;
      CONLANG_STYLE = TextStyle(fontFamily: CONLANG_FONT, fontSize: BASE_CONLANG_FONT_SIZE);
      BASELANG_FONT = language.baselang_font;
      BASE_BASELANG_FONT_SIZE = language.base_baselang_font_size ?? DEFAULT_FONT_SIZE;
      BASELANG_STYLE = TextStyle(fontFamily: BASELANG_FONT, fontSize: BASE_BASELANG_FONT_SIZE);

      LARGER_CONLANG_STYLE = CONLANG_STYLE.copyWith(fontSize: BASE_CONLANG_FONT_SIZE * 1.2);
      LARGER_BASELANG_STYLE = BASELANG_STYLE.copyWith(fontSize: BASE_CONLANG_FONT_SIZE * 1.2);
      APPBAR_CONLANG_STYLE = CONLANG_STYLE.copyWith(fontSize: BASE_CONLANG_FONT_SIZE * 1.5);

      WORD_STYLE = CONLANG_STYLE.copyWith(fontSize: BASE_CONLANG_FONT_SIZE * 1.25);
      WORD_NUMBER_STYLE = BASELANG_STYLE.copyWith(fontSize: BASE_BASELANG_FONT_SIZE * 0.6);
      POS_STYLE = BASELANG_STYLE.copyWith(fontStyle: FontStyle.italic, color: PRIMARY_TEXT_COLOUR);
      PRONUNCIATION_STYLE = BASELANG_STYLE.copyWith(color: ACCENT_TEXT_COLOUR);
      TRANSLATION_STYLE = BASELANG_STYLE;
      ETYMOLOGY_STYLE = BASELANG_STYLE.copyWith(color: make_text_colour_strong(Colors.green));
      NOTES_STYLE = BASELANG_STYLE.copyWith(color: make_text_colour_strong(PRIMARY_COLOUR));
    }
  }
}

class AppThemeProvider extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  String theme;
  Color? background_colour;
  Color? primary_colour;
  Color? secondary_colour;

  AppThemeProvider({
    required this.builder,
    required this.theme,
    this.background_colour,
    required this.primary_colour,
    required this.secondary_colour,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Language>(
      builder: (context, language) {
        ThemeColours theme_colours = ThemeColours(
          theme_name: theme,
          background_colour: background_colour,
          primary_colour: primary_colour,
          secondary_colour: secondary_colour,
          language: language,
          platform: Theme.of(context).platform,
          localizations: DefaultMaterialLocalizations(),
        );

        return Theme(
          data: theme_colours.theme,
          child: DefaultTextStyle(
            style: DefaultTextStyle.of(context).style.copyWith(color: theme_colours.BASE_TEXT_COLOUR),
            child: Provider<ZarainiaTheme>.value(
              value: theme_colours,
              builder: (context, widget) => builder(context),
            ),
          ),
        );
      },
    );
  }
}

ThemeColours get_theme_colours(BuildContext context) {
  return get_zarainia_theme(context) as ThemeColours;
}
