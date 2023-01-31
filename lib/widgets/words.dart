import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_improved_scrolling/flutter_improved_scrolling.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:unified_sounds/unified_sounds.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/filter_settings_cubit.dart';
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/cubits/word_list_cubit.dart';
import 'package:dictionary_editor/cubits/words_cubit.dart';
import 'package:dictionary_editor/objects/filter_settings.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/objects/word.dart';
import 'package:dictionary_editor/pages/word.dart';
import 'package:dictionary_editor/theme.dart';
import 'package:dictionary_editor/util/utils.dart';

class BracketedText extends StatelessWidget {
  String left;
  String centre;
  String right;
  TextStyle? style;
  MainAxisAlignment main_alignment;

  BracketedText({
    required this.left,
    required this.right,
    required this.centre,
    this.style,
    this.main_alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(left, style: style),
        PaddinglessSelectableText(centre, style: style),
        Text(right, style: style),
      ],
      mainAxisAlignment: main_alignment,
    );
  }
}

class _WordAudioPlayback extends StatefulWidget {
  final Uint8List audio;

  const _WordAudioPlayback({required this.audio});

  @override
  _WordAudioPlaybackState createState() => _WordAudioPlaybackState();
}

class _WordAudioPlaybackState extends State<_WordAudioPlayback> {
  AudioPlayer player = AudioPlayer();

  Future play_audio() async {
    player.reset();
    await player.load_bytes(widget.audio, "word_sound.aac");
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return IconButton(
      icon: Icon(Icons.volume_up),
      iconSize: 20,
      color: theme_colours.PRIMARY_ICON_COLOUR,
      onPressed: play_audio,
      tooltip: "Play audio",
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}

class _WordEntry extends StatelessWidget {
  final Word word;
  final Set<PartOfSpeech> pos;
  final bool last;
  final VoidCallback? on_click;

  const _WordEntry({required this.word, this.pos = const {}, this.last = false, this.on_click});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return InkWell(
      child: Container(
        child: Row(
          children: [
            Expanded(
              child: BlocBuilder<SettingsCubit, Settings>(
                builder: (context, settings) => BlocBuilder<FilterSettingsCubit, FilterSettings>(
                  builder: (context, filter_settings) => BlocBuilder<LettersCubit, LetterInfo>(
                    builder: (context, letter_info) => Column(
                      children: [
                        Row(
                          children: [
                            highlight_search_text(
                              word.name,
                              conlang: true,
                              context: context,
                              settings: settings,
                              filter_settings: filter_settings,
                              letter_info: letter_info,
                              base_style: theme_colours.WORD_STYLE,
                            ),
                            if (word.number != null)
                              Transform.translate(
                                offset: const Offset(0, -7),
                                child: Text(word.number!.toString(), style: theme_colours.WORD_NUMBER_STYLE),
                              ),
                            if (pos.isNotEmpty)
                              Flexible(
                                child: Padding(
                                  child: Text(
                                    "(${pos.map((pos) => pos.name).join(", ")})",
                                    style: theme_colours.POS_STYLE,
                                  ),
                                  padding: const EdgeInsets.only(left: 3),
                                ),
                              ),
                            if (word.audio != null && word.audio!.isNotEmpty) _WordAudioPlayback(audio: word.audio!),
                          ],
                        ),
                        if (word.pronunciation != null)
                          Padding(
                            child: BracketedText(
                              left: '/',
                              right: '/',
                              centre: word.pronunciation!,
                              style: theme_colours.PRONUNCIATION_STYLE,
                            ),
                            padding: const EdgeInsets.only(top: 5),
                          ),
                        if (word.translations.isNotEmpty)
                          Padding(
                            child: Column(
                              children: word.translations
                                  .map(
                                    (translation) => highlight_search_text(
                                      translation.translation,
                                      context: context,
                                      settings: settings,
                                      filter_settings: filter_settings,
                                      letter_info: letter_info,
                                      base_style: theme_colours.TRANSLATION_STYLE,
                                    ),
                                  )
                                  .toList(),
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ),
                            padding: const EdgeInsets.only(top: 7),
                          ),
                        if (word.etymology != null) BracketedText(centre: word.etymology!, left: '[', right: ']', style: theme_colours.ETYMOLOGY_STYLE),
                        if (word.notes != null) BracketedText(centre: word.notes!, left: '(', right: ')', style: theme_colours.NOTES_STYLE),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => context.read<WordsCubit>().delete(word.id),
            )
          ],
        ),
        padding: EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
        decoration: last ? null : BoxDecoration(border: Border(bottom: BorderSide(color: theme_colours.BORDER_COLOUR))),
      ),
      focusColor: Colors.transparent,
      onTap: on_click,
    );
  }
}

class WordsList extends StatefulWidget {
  final LetterInfo letter_info;
  final Function(int) select_word;
  final AutoScrollController scroll_controller;

  const WordsList({
    required this.letter_info,
    required this.select_word,
    required this.scroll_controller,
  });

  @override
  _WordsListState createState() => _WordsListState();
}

class _WordsListState extends State<WordsList> {
  Set<int> visible_indices = {};

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return Stack(
      children: [
        BlocBuilder<WordListCubit, List<Word>>(
          builder: (context, words) {
            return BlocBuilder<PartsOfSpeechCubit, PartOfSpeechInfo>(
              builder: (context, pos_info) => ImprovedScrolling(
                scrollController: widget.scroll_controller,
                enableKeyboardScrolling: true,
                child: DraggableScrollbar.rrect(
                  labelTextBuilder: (offset) {
                    String text;
                    if (visible_indices.isEmpty)
                      text = "";
                    else {
                      Word first_word = words[visible_indices.min];
                      text = widget.letter_info.upper(first_word.name.isNotEmpty ? widget.letter_info.split_word(first_word.name)[0] : "");
                    }
                    return Text(
                      text,
                      style: theme_colours.CONLANG_STYLE.copyWith(fontSize: 24, color: theme_colours.TEXT_ON_ACCENT_COLOUR),
                    );
                  },
                  labelConstraints: const BoxConstraints(maxHeight: 60, maxWidth: 60),
                  backgroundColor: theme_colours.ACCENT_COLOUR,
                  child: CustomScrollView(
                    slivers: [
                      SuperSliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            Word word = words[index];
                            return AutoScrollTag(
                              key: ValueKey(index),
                              controller: widget.scroll_controller,
                              index: index,
                              child: VisibilityDetector(
                                  key: ValueKey(word.id),
                                  child: _WordEntry(
                                    word: word,
                                    last: index == words.length - 1,
                                    pos: pos_info.pos_by_words[word.id] ?? const {},
                                    on_click: () {
                                      double device_width = MediaQuery.of(context).size.width;
                                      widget.select_word(word.id);
                                      if (device_width < constants.TWO_PANEL_CUTOFF_WIDTH) show_word_page(context, word);
                                    },
                                  ),
                                  onVisibilityChanged: (visible) {
                                    if (visible.visibleFraction > 0)
                                      setState(() {
                                        visible_indices.add(index);
                                      });
                                    else
                                      setState(() {
                                        visible_indices.remove(index);
                                      });
                                  }),
                            );
                          },
                          childCount: words.length,
                        ),
                      ),
                    ],
                    controller: widget.scroll_controller,
                  ),
                  controller: widget.scroll_controller,
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () => show_word_page(context),
            backgroundColor: theme_colours.ACCENT_COLOUR,
          ),
        ),
      ],
    );
  }
}
