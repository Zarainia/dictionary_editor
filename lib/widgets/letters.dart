import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intersperse/intersperse.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/cubits/word_list_cubit.dart';
import 'package:dictionary_editor/objects/letter.dart';
import 'package:dictionary_editor/objects/word.dart';
import 'package:dictionary_editor/theme.dart';

class _LetterButton extends StatelessWidget {
  final Letter letter;
  final Function(Letter) scroll_to_letter;

  const _LetterButton({required this.letter, required this.scroll_to_letter});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return Tooltip(
      child: ZarainiaTheme.on_appbar_theme_provider(
        context,
        (context) => InkWell(
          child: Text(
            letter.uppercase,
            style: theme_colours.CONLANG_STYLE.copyWith(fontSize: theme_colours.BASE_CONLANG_FONT_SIZE * 1.2),
          ),
          onTap: () => scroll_to_letter(letter),
        ),
      ),
      richMessage: TextSpan(
        children: [
          TextSpan(text: "Jump to "),
          TextSpan(
            text: letter.uppercase,
            style: theme_colours.CONLANG_STYLE.copyWith(fontSize: theme_colours.BASE_CONLANG_FONT_SIZE * 0.8),
          ),
        ],
      ),
    );
  }
}

class LetterBar extends StatelessWidget {
  final LetterInfo letter_info;
  final AutoScrollController words_scroll_controller;

  const LetterBar({required this.letter_info, required this.words_scroll_controller});

  void scroll_to_letter(List<Word> words, Letter letter) {
    int index = words.indexWhere((word) => word.name.isNotEmpty && letter_info.normalize(letter_info.split_word(word.name)[0]) == letter.search_normalization);
    if (index >= 0) words_scroll_controller.scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
  }

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return BlocBuilder<WordListCubit, List<Word>>(
      builder: (context, words) => SizedBox(
        child: Material(
          child: Padding(
            child: Wrap(
              children: intersperse(
                const SizedBox(width: 10),
                letter_info.letters.map(
                  (letter) => _LetterButton(
                    letter: letter,
                    scroll_to_letter: (letter) => scroll_to_letter(words, letter),
                  ),
                ),
              ).toList(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          color: theme_colours.PRIMARY_COLOUR,
          elevation: 8,
        ),
        width: double.infinity,
      ),
    );
  }
}
