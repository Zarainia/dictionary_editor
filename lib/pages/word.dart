import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intersperse/intersperse.dart';
import 'package:record/record.dart';
import 'package:unified_sounds/sounds.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'package:dictionary_editor/objects/word.dart';
import 'package:dictionary_editor/theme.dart';
import 'package:dictionary_editor/widgets/misc.dart';
import 'package:dictionary_editor/widgets/page.dart';

void show_word_page(BuildContext context, [Word? word]) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => WordPage(curr_word: word ?? const Word.initial())),
  );
}

class _WordWithPartOfSpeech {
  final Word word;
  final ISet<int> pos_ids;

  _WordWithPartOfSpeech({required this.word, this.pos_ids = const ISetConst({})});

  Future save(BuildContext context, _WordWithPartOfSpeech original) async {
    if (word != original.word) await word.save(context, original.word);
    if (pos_ids != original.pos_ids) {
      PartsOfSpeechCubit pos_cubit = BlocProvider.of<PartsOfSpeechCubit>(context);
      for (int pos_id in pos_ids.difference(original.pos_ids)) await pos_cubit.insert_word_pos(WordPartOfSpeech(word_id: word.id, pos_id: pos_id));
      for (int pos_id in original.pos_ids.difference(pos_ids)) await pos_cubit.delete_word_pos(word.id, pos_id);
    }
  }

  _WordWithPartOfSpeech copy_with({
    Word? word,
    ISet<int>? pos_ids,
  }) {
    return _WordWithPartOfSpeech(word: word ?? this.word, pos_ids: pos_ids ?? this.pos_ids);
  }

  @override
  int get hashCode => Object.hash(word, pos_ids);

  @override
  bool operator ==(Object other) {
    return other is _WordWithPartOfSpeech && other.word == word && other.pos_ids == pos_ids;
  }
}

class _PartOfSpeechChip extends StatelessWidget {
  final PartOfSpeech pos;
  final VoidCallback delete_func;

  const _PartOfSpeechChip({required this.pos, required this.delete_func});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);
    return InputChip(
      label: Padding(child: Text(pos.name), padding: EdgeInsets.only(bottom: 3)),
      onDeleted: delete_func,
      backgroundColor: theme_colours.ACCENT_COLOUR,
      deleteIcon: const Icon(Icons.close, size: 20),
      elevation: 4,
    );
  }
}

class _PartOfSpeechEditor extends StatelessWidget {
  final ISet<int> pos_ids;
  final Function(ISet<int>) on_change;

  const _PartOfSpeechEditor({required this.pos_ids, required this.on_change});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return BlocBuilder<PartsOfSpeechCubit, PartOfSpeechInfo>(
      builder: (context, pos_info) => Wrap(
        children: [
          IconAndText(icon: constants.PART_OF_SPEECH_ICON, text: "Part of speech", style: theme_colours.SMALL_HEADER_STYLE),
          const SizedBox(width: 20),
          ...pos_ids.map(
            (pos_id) => _PartOfSpeechChip(
              pos: pos_info.pos[pos_id]!,
              delete_func: () => on_change(pos_ids.remove(pos_id)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SimpleSelectDialog(
                  item_name: "part of speech",
                  item_name_plural: "parts of speech",
                  all_options: pos_info.pos.values.where((pos) => !pos_ids.contains(pos.id)).sortedBy((pos) => pos.name).toList(),
                  confirm_callback: (context, pos) => on_change(pos_ids.add(pos.first.id)),
                  display_convertor: (pos) => pos.name,
                  icon: Icons.category,
                ),
              );
            },
            constraints: const BoxConstraints(maxHeight: 500),
            tooltip: "Add part of speech",
          ),
        ],
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 5,
      ),
    );
  }
}

class _TranslationEntry extends StatelessWidget {
  final Translation curr_translation;
  final Function(Translation) save_func;
  final VoidCallback? delete_func;
  final VoidCallback? finish_callback;
  final bool initially_editing;

  const _TranslationEntry({
    super.key,
    required this.curr_translation,
    required this.save_func,
    this.delete_func,
    this.finish_callback,
    this.initially_editing = false,
  });

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return StagedEditor(
      initial_value: curr_translation.translation,
      on_confirm: (translation) {
        save_func(curr_translation.copy_with(translation: translation));
        finish_callback?.call();
      },
      on_cancel: (_) => finish_callback?.call(),
      initially_editing: initially_editing,
      editor_builder: ({
        required bool editing,
        required Function() start_editing,
        required String value,
        required Function(String) update_value,
        required Function(List<String>) update_errors,
        VoidCallback? save,
        required VoidCallback cancel,
        required List<String> errors,
      }) {
        return MultiErrorManager(
          widget_ids: {"translation"},
          update_errors: update_errors,
          builder: (error_updater) => ListTile(
            title: editing
                ? StatedTextField(
                    initial_text: value,
                    on_changed: update_value,
                    validator: const EmptyValidator(field: "translation"),
                    style: theme_colours.LARGER_BASELANG_STYLE,
                    decoration: TextFieldBorder(context: context, hintText: "Translation"),
                    on_error: (error) => error_updater("translation", error),
                  )
                : Text(curr_translation.translation, style: theme_colours.LARGER_BASELANG_STYLE),
            trailing: Row(
              children: [
                if (!editing)
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: start_editing,
                    tooltip: "Edit",
                  ),
                if (!editing)
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: delete_func,
                    tooltip: "Delete",
                  ),
                if (editing)
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: save,
                    tooltip: "Save",
                  ),
                if (editing)
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: cancel,
                    tooltip: "Cancel",
                  ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        );
      },
    );
  }
}

class _TranslationsEditor extends StatefulWidget {
  final Word word;
  final IList<Translation> curr_translations;
  final Function(IList<Translation>) on_change;

  _TranslationsEditor({required this.word, required this.curr_translations, required this.on_change});

  @override
  _TranslationsEditorState createState() => _TranslationsEditorState();
}

class _TranslationsEditorState extends State<_TranslationsEditor> {
  bool new_entry_showing = false;

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return Column(
      children: [
        IconAndText(icon: constants.TRANSLATION_ICON, text: "Translations", style: theme_colours.SMALL_HEADER_STYLE),
        const SizedBox(height: 10),
        ListView.builder(
          itemCount: widget.curr_translations.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.curr_translations.length) {
              if (new_entry_showing)
                return _TranslationEntry(
                  key: Key("new_translation"),
                  curr_translation: Translation.initial(word_id: widget.word.id),
                  save_func: (translation) => widget.on_change(widget.curr_translations.add(translation)),
                  finish_callback: () {
                    setState(() {
                      new_entry_showing = false;
                    });
                  },
                  initially_editing: true,
                );
              else
                return ListEndAddButton(
                  on_click: () {
                    setState(() {
                      new_entry_showing = true;
                    });
                  },
                  tooltip: "Add translation",
                );
            }
            return _TranslationEntry(
              curr_translation: widget.curr_translations[index],
              save_func: (translation) => widget.on_change(widget.curr_translations.replace(index, translation)),
              delete_func: () => widget.on_change(widget.curr_translations.removeAt(index)),
            );
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _AudioControlIcon extends StatelessWidget {
  final IconData icon;
  final double icon_size_adjustment;
  final String? tooltip;
  final VoidCallback inactive_action;
  final VoidCallback? active_action;
  final bool active;
  final bool enabled;

  _AudioControlIcon({
    required this.icon,
    this.icon_size_adjustment = 1,
    required this.inactive_action,
    this.active_action,
    this.tooltip,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return IconButton(
      icon: Icon(icon),
      iconSize: 27 * icon_size_adjustment,
      color: active ? theme_colours.ACCENT_COLOUR : theme_colours.ICON_COLOUR,
      onPressed: enabled ? (active ? active_action ?? inactive_action : inactive_action) : null,
      tooltip: tooltip,
    );
  }
}

class _AudioRecorder extends StatefulWidget {
  final Uint8List? audio;
  final Function(Uint8List?) on_change;

  const _AudioRecorder({this.audio, required this.on_change});

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<_AudioRecorder> {
  AudioPlayer player = AudioPlayer();
  Record recorder = Record();

  bool playing = false;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    player.playback_callback = (status) {
      setState(() {
        playing = status.is_playing;
      });
    };
  }

  Future play_audio() async {
    player.reset();
    await player.load_bytes(widget.audio!, "word_sound.aac");
    player.play();
  }

  Future stop_audio() async {
    player.stop();
  }

  Future start_recording() async {
    if (await recorder.hasPermission()) {
      await recorder.start(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
      setState(() {
        recording = true;
      });
    }
  }

  Future stop_recording() async {
    String? path = await recorder.stop();
    setState(() {
      recording = false;
    });
    if (path != null) {
      File file = new File(path);
      Uint8List bytes = await file.readAsBytes();
      widget.on_change(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return Column(
      children: [
        Row(
          children: [
            IconAndText(icon: constants.SOUND_ICON, text: "Audio", style: theme_colours.SMALL_HEADER_STYLE),
            const SizedBox(width: 20),
            _AudioControlIcon(
              icon: Icons.play_arrow,
              icon_size_adjustment: 1.3,
              inactive_action: play_audio,
              active_action: stop_audio,
              enabled: !recording && widget.audio != null && widget.audio!.isNotEmpty,
              active: playing,
              tooltip: "Play",
            ),
            _AudioControlIcon(
              icon: Icons.fiber_manual_record,
              inactive_action: start_recording,
              active_action: stop_recording,
              active: recording,
              tooltip: "Record",
            ),
            if (widget.audio != null)
              _AudioControlIcon(
                icon: Icons.delete,
                inactive_action: () => widget.on_change(null),
                tooltip: "Delete",
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}

class _WordEditor extends StatelessWidget {
  final _WordWithPartOfSpeech curr_value;
  final Function(_WordWithPartOfSpeech) on_change;
  final Function(List<String>) update_errors;

  _WordEditor({required this.curr_value, required this.on_change, required this.update_errors});

  void on_word_change(Word word) {
    on_change(curr_value.copy_with(word: word));
  }

  void on_pos_ids_change(ISet<int> pos_ids) {
    on_change(curr_value.copy_with(pos_ids: pos_ids));
  }

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return MultiErrorManager(
      widget_ids: {"word"},
      update_errors: update_errors,
      builder: (update_error) => SingleChildScrollView(
        child: Column(
          children: [
            _PartOfSpeechEditor(pos_ids: curr_value.pos_ids, on_change: on_pos_ids_change),
            const SizedBox(height: 30),
            ...intersperse(
              const SizedBox(height: 20),
              [
                StatedTextField(
                  initial_text: curr_value.word.name,
                  on_changed: (name) => on_word_change(curr_value.word.copy_with(name: name)),
                  style: theme_colours.LARGER_CONLANG_STYLE,
                  decoration: TextFieldBorder(context: context, labelText: "Word", labelStyle: theme_colours.DEFAULT_INPUT_LABEL_STYLE),
                  validator: const EmptyValidator(),
                  on_error: (error) => update_error("word", error),
                ),
                StatedTextField(
                  initial_text: curr_value.word.pronunciation,
                  on_changed: (pronunciation) => on_word_change(curr_value.word.copy_with(pronunciation: pronunciation)),
                  style: theme_colours.LARGER_BASELANG_STYLE,
                  decoration: TextFieldBorder(context: context, labelText: "Pronunciation"),
                ),
                StatedTextField(
                  initial_text: curr_value.word.etymology,
                  on_changed: (etymology) => on_word_change(curr_value.word.copy_with(etymology: etymology)),
                  style: theme_colours.LARGER_BASELANG_STYLE,
                  decoration: TextFieldBorder(context: context, labelText: "Etymology"),
                ),
                StatedTextField(
                  initial_text: curr_value.word.notes,
                  on_changed: (notes) => on_word_change(curr_value.word.copy_with(notes: notes)),
                  style: theme_colours.LARGER_BASELANG_STYLE,
                  decoration: TextFieldBorder(context: context, labelText: "Notes"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _AudioRecorder(
              audio: curr_value.word.audio,
              on_change: (audio) => on_word_change(curr_value.word.copy_with(audio: audio)),
            ),
            const SizedBox(height: 30),
            _TranslationsEditor(
              word: curr_value.word,
              curr_translations: curr_value.word.translations,
              on_change: (translations) => on_word_change(
                curr_value.word.copy_with(translations: translations),
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.stretch,
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final String text;
  final VoidCallback? on_click;

  const _PanelButton({required this.text, this.on_click});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return ElevatedButton(
      child: Padding(
        child: Text(text.toUpperCase()),
        padding: const EdgeInsets.all(7),
      ),
      onPressed: on_click,
      style: theme_colours.theme.elevatedButtonTheme.style!.copyWith(
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
        ),
      ),
    );
  }
}

class WordPanel extends StatelessWidget {
  final Word curr_word;
  final VoidCallback close_panel;

  const WordPanel({super.key, required this.curr_word, required this.close_panel});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return Container(
      child: BlocBuilder<PartsOfSpeechCubit, PartOfSpeechInfo>(
        builder: (context, pos_info) {
          _WordWithPartOfSpeech curr_value = _WordWithPartOfSpeech(
            word: curr_word,
            pos_ids: pos_info.pos_by_words[curr_word.id]?.map((pos) => pos.id).toISet() ?? const ISetConst({}),
          );

          return StagedEditor(
            initial_value: curr_value,
            always_editing: true,
            editor_builder: ({
              required bool editing,
              required Function() start_editing,
              required _WordWithPartOfSpeech value,
              required Function(_WordWithPartOfSpeech) update_value,
              required Function(List<String>) update_errors,
              VoidCallback? save,
              required VoidCallback cancel,
              required List<String> errors,
            }) {
              return Column(
                children: [
                  Expanded(
                    child: _WordEditor(
                      curr_value: value,
                      on_change: update_value,
                      update_errors: update_errors,
                    ),
                  ),
                  Row(
                    children: [
                      _PanelButton(text: "Close", on_click: close_panel),
                      const SizedBox(width: 10),
                      _PanelButton(text: "Reset", on_click: cancel),
                      const SizedBox(width: 10),
                      _PanelButton(text: "Save", on_click: save),
                    ],
                    mainAxisAlignment: MainAxisAlignment.end,
                  ),
                ],
              );
            },
            on_confirm: (value) => value.save(context, curr_value),
          );
        },
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: theme_colours.BORDER_COLOUR))),
    );
  }
}

class WordPage extends StatelessWidget {
  final Word curr_word;

  const WordPage({required this.curr_word});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return BlocBuilder<PartsOfSpeechCubit, PartOfSpeechInfo>(
      builder: (context, pos_info) {
        _WordWithPartOfSpeech curr_value = _WordWithPartOfSpeech(
          word: curr_word,
          pos_ids: pos_info.pos_by_words[curr_word.id]?.map((pos) => pos.id).toISet() ?? const ISetConst({}),
        );

        return StagedEditor(
          initial_value: curr_value,
          always_editing: true,
          editor_builder: ({
            required bool editing,
            required Function() start_editing,
            required _WordWithPartOfSpeech value,
            required Function(_WordWithPartOfSpeech) update_value,
            required Function(List<String>) update_errors,
            VoidCallback? save,
            required VoidCallback cancel,
            required List<String> errors,
          }) {
            return DialogPage(
              appbar: AppBar(
                leading: ZarainiaTheme.on_appbar_theme_provider(
                  context,
                  (context) => IconButton(
                    icon: Icon(Icons.check),
                    onPressed: save != null
                        ? () {
                            save();
                            Navigator.of(context).pop();
                          }
                        : null,
                    tooltip: "Save",
                  ),
                  bright_icons: true,
                ),
                title: Text(value.word.name, style: theme_colours.APPBAR_CONLANG_STYLE),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      cancel();
                      Navigator.of(context).pop();
                    },
                    tooltip: "Close",
                  ),
                ],
              ),
              child: _WordEditor(
                curr_value: value,
                on_change: update_value,
                update_errors: update_errors,
              ),
            );
          },
          on_confirm: (value) => value.save(context, curr_value),
        );
      },
    );
  }
}
