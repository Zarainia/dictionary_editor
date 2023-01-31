import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intersperse/intersperse.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/language_cubit.dart';
import 'package:dictionary_editor/objects/language.dart';

void show_language_dialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LanguageDialog(),
  );
}

class _LanguageSettings {
  final String conlang_name;
  final String baselang_name;

  const _LanguageSettings({
    required this.conlang_name,
    required this.baselang_name,
  });

  _LanguageSettings.from_language(Language language)
      : conlang_name = language.conlang_name,
        baselang_name = language.baselang_name;

  Future save_settings(BuildContext context) async {
    await context.read<LanguageCubit>().edit_values({
      Language.CONLANG_NAME_SETTING: conlang_name,
      Language.BASELANG_NAME_SETTING: baselang_name,
    });
  }

  _LanguageSettings copy_with({
    String? conlang_name,
    String? baselang_name,
  }) {
    return _LanguageSettings(
      conlang_name: conlang_name ?? this.conlang_name,
      baselang_name: baselang_name ?? this.baselang_name,
    );
  }

  @override
  int get hashCode => Object.hash(conlang_name, baselang_name);

  @override
  bool operator ==(Object other) {
    return other is _LanguageSettings && other.conlang_name == conlang_name && other.baselang_name == baselang_name;
  }
}

class _LanguageEditor extends StatelessWidget {
  final _LanguageSettings curr_language_settings;
  final Function(_LanguageSettings) on_change;
  final Function(List<String>) update_errors;

  const _LanguageEditor({required this.curr_language_settings, required this.on_change, required this.update_errors});

  @override
  Widget build(BuildContext context) {
    return MultiErrorManager(
      widget_ids: {"conlang_name", "baselang_name"},
      update_errors: update_errors,
      builder: (error_updater) => Column(
        children: intersperse(
          const SizedBox(height: 20),
          [
            StatedTextField(
              initial_text: curr_language_settings.conlang_name,
              on_changed: (name) => on_change(curr_language_settings.copy_with(conlang_name: name)),
              decoration: TextFieldBorder(context: context, labelText: "Conlang Name", hintText: "Conlang", show_error_text: false),
              validator: const EmptyValidator(field: "conlang name"),
              on_error: (error) => error_updater("conlang_name", error),
            ),
            StatedTextField(
              initial_text: curr_language_settings.baselang_name,
              on_changed: (name) => on_change(curr_language_settings.copy_with(baselang_name: name)),
              decoration: TextFieldBorder(context: context, labelText: "Base language Name", hintText: "Base language", show_error_text: false),
              validator: const EmptyValidator(field: "base language name"),
              on_error: (error) => error_updater("baselang_name", error),
            ),
          ],
        ).toList(),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class LanguageDialog extends StatelessWidget {
  const LanguageDialog();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Language>(
      builder: (context, language) => EditDialog(
        title: "Language",
        initial_value: _LanguageSettings.from_language(language),
        editor_builder: (curr_language_settings, on_change, update_errors) => _LanguageEditor(
          curr_language_settings: curr_language_settings,
          on_change: on_change,
          update_errors: update_errors,
        ),
        on_confirm: (language_settings) => language_settings.save_settings(context),
      ),
    );
  }
}
