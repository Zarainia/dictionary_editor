import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intersperse/intersperse.dart';
import 'package:synchronized/synchronized.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/objects/letter.dart';
import 'package:dictionary_editor/theme.dart';
import 'package:dictionary_editor/widgets/misc.dart';
import 'package:dictionary_editor/widgets/shortcuts.dart';

void show_letters_dialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LettersDialog(),
  );
}

String _get_variant_title(Variant variant) {
  if (variant.uppercase == variant.lowercase)
    return variant.lowercase;
  else
    return "${variant.uppercase}/${variant.lowercase}";
}

class _VariantEditor extends StatelessWidget {
  final Variant curr_variant;
  final Function(Variant) on_change;
  final Function(String?) update_error;

  const _VariantEditor({required this.curr_variant, required this.on_change, required this.update_error});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);
    TextStyle input_style = theme_colours.LARGER_CONLANG_STYLE;

    return Column(
      children: intersperse(
        const SizedBox(height: 20),
        [
          StatedTextField(
            initial_text: curr_variant.lowercase,
            on_changed: (lowercase) => on_change(curr_variant.copy_with(lowercase: lowercase)),
            style: input_style,
            decoration: TextFieldBorder(context: context, labelText: "Lowercase"),
            validator: const EmptyValidator(field: "lowercase"),
            on_error: update_error,
          ),
          StatedTextField(
            initial_text: curr_variant.actual_uppercase,
            on_changed: (uppercase) => on_change(curr_variant.copy_with(uppercase: uppercase)),
            style: input_style,
            decoration: TextFieldBorder(context: context, labelText: "Uppercase", hintText: curr_variant.lowercase),
          ),
        ],
      ).toList(),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

void _show_variant_dialog({required BuildContext context, required int letter_id, Variant? variant, required Function(Variant) on_confirm}) {
  showDialog(
    context: context,
    builder: (context) => _VariantEditorDialog(
      variant: variant ?? Variant.initial(letter_id: letter_id),
      on_confirm: on_confirm,
    ),
  );
}

class _VariantEditorDialog extends StatelessWidget {
  final Variant variant;
  final Function(Variant) on_confirm;

  const _VariantEditorDialog({required this.variant, required this.on_confirm});

  @override
  Widget build(BuildContext context) {
    return EditDialog(
      title: "Letter",
      initial_value: variant,
      show_error_text: false,
      editor_builder: (curr_variant, on_change, update_errors) => MultiErrorManager(
        widget_ids: {"lowercase"},
        update_errors: update_errors,
        builder: (update_error) => _VariantEditor(
          curr_variant: curr_variant,
          on_change: on_change,
          update_error: (error) => update_error("lowercase", error),
        ),
      ),
      on_confirm: on_confirm,
    );
  }
}

class _VariantEntry extends StatelessWidget {
  final Letter letter;
  final Variant variant;
  final VoidCallback delete_func;
  final Function(Variant) confirm_func;

  const _VariantEntry({required this.letter, required this.variant, required this.delete_func, required this.confirm_func});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return ListTile(
      title: Text(_get_variant_title(variant), style: theme_colours.LARGER_CONLANG_STYLE),
      trailing: Row(
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _show_variant_dialog(context: context, letter_id: letter.id, variant: variant, on_confirm: confirm_func),
            tooltip: "Edit",
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: delete_func,
            tooltip: "Delete",
          ),
        ],
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }
}

int _get_last_position(BuildContext context) {
  int? last_position = BlocProvider.of<LettersCubit>(context).state.letters.lastOrNull?.position;
  return last_position != null ? (last_position + 1) : 0;
}

void _show_letter_dialog(BuildContext context, [Letter? letter]) {
  showDialog(
    context: context,
    builder: (context) => _LetterEditorDialog(
      letter: letter ?? Letter.initial(position: _get_last_position(context)),
    ),
  );
}

class _LetterEditorDialog extends StatelessWidget {
  final Letter letter;

  const _LetterEditorDialog({required this.letter});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return EditDialog(
      title: "Letter",
      initial_value: letter,
      show_error_text: false,
      editor_builder: (curr_letter, on_change, update_errors) => MultiErrorManager(
        widget_ids: {"main_variant_lowercase"},
        update_errors: update_errors,
        builder: (update_error) => Column(
          children: [
            _VariantEditor(
              curr_variant: curr_letter.main_variant,
              on_change: (variant) => on_change(curr_letter.copy_with(main_variant: variant)),
              update_error: (error) => update_error("main_variant_lowercase", error),
            ),
            const SizedBox(height: 20),
            StatedTextField(
              initial_text: curr_letter.actual_search_normalization,
              on_changed: (normalization) => on_change(curr_letter.copy_with(search_normalization: normalization)),
              style: theme_colours.LARGER_CONLANG_STYLE,
              decoration: TextFieldBorder(context: context, labelText: "Search normalization", hintText: curr_letter.lowercase),
            ),
            const SizedBox(height: 20),
            Text("Variants", style: theme_colours.SMALLER_HEADER_STYLE),
            ...curr_letter.other_variants.mapIndexed(
              (index, variant) => _VariantEntry(
                letter: curr_letter,
                variant: variant,
                delete_func: () => on_change(
                  curr_letter.copy_with(
                    other_variants: curr_letter.other_variants.removeAt(index),
                  ),
                ),
                confirm_func: (edited_variant) => on_change(
                  curr_letter.copy_with(
                    other_variants: curr_letter.other_variants.replace(index, edited_variant),
                  ),
                ),
              ),
            ),
            ListEndAddButton(
              on_click: () => _show_variant_dialog(
                context: context,
                letter_id: curr_letter.id,
                on_confirm: (new_variant) => on_change(
                  curr_letter.copy_with(
                    other_variants: curr_letter.other_variants.add(
                      new_variant,
                    ),
                  ),
                ),
              ),
              tooltip: "Add variant",
            )
          ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        ),
      ),
      on_confirm: (edited_letter) => edited_letter.save(context, letter),
    );
  }
}

class _LetterEntry extends StatelessWidget {
  final Letter letter;

  const _LetterEntry({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return ReorderableDragStartListener(
      child: ListTile(
        title: Text(_get_variant_title(letter.main_variant), style: theme_colours.LARGER_CONLANG_STYLE),
        trailing: Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _show_letter_dialog(context, letter),
              tooltip: "Edit",
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => context.read<LettersCubit>().delete(letter.id),
              tooltip: "Delete",
            ),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      ),
      index: letter.position,
    );
  }
}

class LettersDialog extends StatelessWidget {
  static Lock _reorder_lock = Lock();

  const LettersDialog();

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return ShortcutsWrapper(
      child: Theme(
        data: theme_colours.theme,
        child: HeaderedButtonlessDialog(
          title: "Letters",
          child: BlocBuilder<LettersCubit, LetterInfo>(
            builder: (context, letter_info) => ReorderableListView.builder(
              itemBuilder: (context, index) {
                Letter letter = letter_info.letters[index];
                return _LetterEntry(key: Key("letter_${letter.id}"), letter: letter);
              },
              footer: ListEndAddButton(
                on_click: () => _show_letter_dialog(context),
                tooltip: "Add letter",
              ),
              itemCount: letter_info.letters.length,
              onReorder: (int index1, int index2) {
                if (index2 > index1) index2--;
                _reorder_lock.synchronized(() async => await context.read<LettersCubit>().reorder(letter_info.letters[index1], index2));
              },
              shrinkWrap: true,
              buildDefaultDragHandles: false,
            ),
          ),
        ),
      ),
    );
  }
}
