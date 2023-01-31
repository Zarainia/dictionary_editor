import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/objects/pos.dart';
import 'package:dictionary_editor/theme.dart';
import 'package:dictionary_editor/widgets/misc.dart';
import 'package:dictionary_editor/widgets/shortcuts.dart';

const BoxConstraints _POS_EDITOR_CONSTRAINTS = BoxConstraints(maxWidth: 400);

void show_pos_dialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const PartOfSpeechDialog(),
  );
}

class _PartOfSpeechEntry extends StatelessWidget {
  final PartOfSpeechInfo pos_info;
  final PartOfSpeech pos;
  final VoidCallback? finish_callback;
  final bool initially_editing;

  const _PartOfSpeechEntry({
    super.key,
    required this.pos_info,
    required this.pos,
    this.finish_callback,
    this.initially_editing = false,
  });

  @override
  Widget build(BuildContext context) {
    VoidCallback delete_pos = () => context.read<PartsOfSpeechCubit>().delete(pos.id);

    return StagedEditor(
      initial_value: pos.name,
      on_confirm: (name) {
        pos.copy_with(name: name).save(context);
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
          widget_ids: {"pos_name"},
          update_errors: update_errors,
          builder: (error_updater) => ListTile(
            title: editing
                ? StatedTextField(
                    initial_text: value,
                    on_changed: update_value,
                    validator: const EmptyValidator(field: "part of speech"),
                    decoration: TextFieldBorder(context: context, hintText: "Part of speech"),
                    on_error: (error) => error_updater("pos_name", error),
                  )
                : Text(pos.name),
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
                    onPressed: () {
                      int usage_count = (pos_info.words_by_pos[pos.id] ?? {}).length;
                      if (usage_count > 0)
                        showDialog(
                          context: context,
                          builder: (context) => ConfirmationDialog(
                            message: "Part of speech in use",
                            contents: "Are you sure you want to delete part of speech? It will be removed from the ${usage_count} words which currently use it.",
                            on_confirm: delete_pos,
                          ),
                        );
                      else
                        delete_pos();
                    },
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

class PartOfSpeechDialog extends StatefulWidget {
  const PartOfSpeechDialog();

  @override
  _PartOfSpeechDialogState createState() => _PartOfSpeechDialogState();
}

class _PartOfSpeechDialogState extends State<PartOfSpeechDialog> {
  bool new_entry_showing = false;

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return ShortcutsWrapper(
      child: Theme(
        data: theme_colours.theme,
        child: HeaderedButtonlessDialog(
          title: "Parts of Speech",
          child: BlocBuilder<PartsOfSpeechCubit, PartOfSpeechInfo>(
            builder: (context, pos_info) {
              List<PartOfSpeech> ordered_pos = pos_info.pos.values.toList();

              return ListView.builder(
                itemBuilder: (context, index) {
                  if (index == pos_info.pos.length) {
                    if (new_entry_showing)
                      return _PartOfSpeechEntry(
                        key: Key("new_pos"),
                        pos_info: pos_info,
                        pos: const PartOfSpeech.initial(),
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
                        tooltip: "Add part of speech",
                      );
                  }
                  PartOfSpeech pos = ordered_pos[index];
                  return _PartOfSpeechEntry(key: Key("pos_${pos.id}"), pos_info: pos_info, pos: pos);
                },
                itemCount: pos_info.pos.length + 1,
                shrinkWrap: true,
              );
            },
          ),
          constraints: _POS_EDITOR_CONSTRAINTS,
        ),
      ),
    );
  }
}
