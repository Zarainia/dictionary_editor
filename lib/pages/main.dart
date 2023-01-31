import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resizable_panel/resizable_panel.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/cubits/words_cubit.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/objects/word.dart';
import 'package:dictionary_editor/pages/word.dart';
import 'package:dictionary_editor/widgets/letters.dart';
import 'package:dictionary_editor/widgets/words.dart';

class MainLayout extends StatelessWidget {
  const MainLayout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WordsCubit, Map<int, Word>>(
      builder: (context, words) => _MainLayoutInner(words: words),
    );
  }
}

class _MainLayoutInner extends StatefulWidget {
  final Map<int, Word> words;

  const _MainLayoutInner({required this.words});

  @override
  _MainLayoutInnerState createState() => _MainLayoutInnerState();
}

class _MainLayoutInnerState extends State<_MainLayoutInner> {
  AutoScrollController words_scroll_controller = AutoScrollController(suggestedRowHeight: 135);

  int? selected_word;

  @override
  void didUpdateWidget(covariant _MainLayoutInner oldWidget) {
    if (selected_word != null && !widget.words.containsKey(selected_word)) select_word(null);
    super.didUpdateWidget(oldWidget);
  }

  void select_word(int? word_id) {
    setState(() {
      selected_word = word_id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LettersCubit, LetterInfo>(
      builder: (context, letter_info) {
        Widget list = WordsList(
          letter_info: letter_info,
          select_word: select_word,
          scroll_controller: words_scroll_controller,
        );

        double device_width = MediaQuery.of(context).size.width;
        Widget content = list;
        if (device_width >= constants.TWO_PANEL_CUTOFF_WIDTH && selected_word != null)
          content = BlocBuilder<SettingsCubit, Settings>(
            builder: (context, settings) => ResizablePanel(
              left: list,
              right: WordPanel(
                key: ValueKey(selected_word),
                curr_word: widget.words[selected_word]!,
                close_panel: () => select_word(null),
              ),
              initial_panel_size: settings.edit_panel_width * device_width,
              on_update_size: (width) => context.read<SettingsCubit>().update_setting(
                    (shared_preferences) => shared_preferences.setDouble(Settings.EDIT_PANEL_WIDTH_SETTING, width / device_width),
                  ),
              left_min_width: constants.PANEL_MIN_WIDTH,
              right_min_width: constants.PANEL_MIN_WIDTH,
            ),
          );

        return Column(
          children: [
            LetterBar(
              letter_info: letter_info,
              words_scroll_controller: words_scroll_controller,
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    words_scroll_controller.dispose();
    super.dispose();
  }
}
