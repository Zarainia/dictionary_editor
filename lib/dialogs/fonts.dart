import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intersperse/intersperse.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/language_cubit.dart';
import 'package:dictionary_editor/objects/language.dart';
import 'package:dictionary_editor/theme.dart';
import 'package:dictionary_editor/util/utils.dart';

void show_font_dialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const FontDialog(),
  );
}

class _FontSettings {
  final String? conlang_font;
  final double? base_conlang_font_size;
  final String? baselang_font;
  final double? base_baselang_font_size;

  const _FontSettings({
    required this.conlang_font,
    required this.base_conlang_font_size,
    required this.base_baselang_font_size,
    required this.baselang_font,
  });

  _FontSettings.from_language(Language language)
      : conlang_font = language.conlang_font,
        base_conlang_font_size = language.base_conlang_font_size,
        baselang_font = language.baselang_font,
        base_baselang_font_size = language.base_baselang_font_size;

  Future save(BuildContext context, _FontSettings original) async {
    if (this != original)
      await context.read<LanguageCubit>().edit_values({
        Language.CONLANG_FONT_SETTING: conlang_font,
        Language.BASE_CONLANG_FONT_SIZE_SETTING: base_conlang_font_size,
        Language.BASELANG_FONT_SETTING: baselang_font,
        Language.BASE_BASELANG_FONT_SIZE_SETTING: base_baselang_font_size,
      });
  }

  _FontSettings copy_with({
    String? conlang_font = constants.IGNORED_STRING_VALUE,
    double? base_conlang_font_size = -1,
    String? baselang_font = constants.IGNORED_STRING_VALUE,
    double? base_baselang_font_size = -1,
  }) {
    return _FontSettings(
      conlang_font: ignore_string_parameter(conlang_font, this.conlang_font),
      base_conlang_font_size: ignore_positive_double_parameter(base_conlang_font_size, this.base_conlang_font_size),
      baselang_font: ignore_string_parameter(baselang_font, this.baselang_font),
      base_baselang_font_size: ignore_positive_double_parameter(base_baselang_font_size, this.base_baselang_font_size),
    );
  }

  @override
  int get hashCode => Object.hash(conlang_font, base_conlang_font_size, baselang_font, base_baselang_font_size);

  @override
  bool operator ==(Object other) {
    return other is _FontSettings &&
        other.conlang_font == conlang_font &&
        other.base_conlang_font_size == base_conlang_font_size &&
        other.baselang_font == baselang_font &&
        other.base_baselang_font_size == base_baselang_font_size;
  }
}

class _FontEditor extends StatelessWidget {
  String? curr_font;
  Function(String?) change_font;
  double? curr_font_size;
  Function(double?) change_font_size;
  double default_font_size;
  Function(String?)? update_error;

  _FontEditor({required this.curr_font, required this.change_font, required this.curr_font_size, required this.change_font_size, this.update_error, this.default_font_size = 10});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatedTextField(
                initial_text: curr_font,
                on_changed: change_font,
                decoration: TextFieldBorder(context: context, labelText: "Font", hintText: "Font"),
              ),
              flex: 2,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatedTextField(
                initial_text: curr_font_size,
                on_changed: change_font_size,
                decoration: TextFieldBorder(
                  context: context,
                  labelText: "Base size",
                  hintText: "Size",
                  show_error_text: false,
                  suffixIcon: TextFieldIncrementButtons(
                    curr_value: curr_font_size ?? default_font_size,
                    on_changed: change_font_size,
                  ),
                ),
                input_formatters: [FloatInputFormatter(2)],
                input_type: TextInputType.number,
                input_convertor: const DoubleInputConvertor(),
                output_convertor: const NullableDoubleOutputConvertor(),
                validator: FloatValidator(field: "font size", minimum: 1, maximum: 40),
                on_error: update_error,
              ),
              flex: 1,
            ),
          ],
        ),
        StatedTextField(
          initial_text: "Preview",
          style: TextStyle(fontFamily: curr_font, fontSize: curr_font_size),
          decoration: const InputDecoration(border: InputBorder.none, focusedBorder: InputBorder.none, hintText: "Preview"),
        )
      ],
    );
  }
}

class _FontsEditor extends StatelessWidget {
  final Language language;
  final _FontSettings curr_font_settings;
  final Function(_FontSettings) on_change;
  final Function(List<String>) update_errors;

  const _FontsEditor({required this.language, required this.curr_font_settings, required this.on_change, required this.update_errors});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return MultiErrorManager(
      widget_ids: {"conlang_font_size", "baselang_font_size"},
      update_errors: update_errors,
      builder: (error_updater) => Column(
        children: intersperse(
          const SizedBox(height: 20),
          [
            Text("${language.conlang_name} font", style: theme_colours.SMALLER_HEADER_STYLE),
            _FontEditor(
              curr_font: curr_font_settings.conlang_font,
              change_font: (font) => on_change(curr_font_settings.copy_with(conlang_font: font)),
              curr_font_size: curr_font_settings.base_conlang_font_size,
              change_font_size: (size) => on_change(curr_font_settings.copy_with(base_conlang_font_size: size)),
              update_error: (error) => error_updater("conlang_font_size", error),
            ),
            Text("${language.baselang_name} font", style: theme_colours.SMALLER_HEADER_STYLE),
            _FontEditor(
              curr_font: curr_font_settings.baselang_font,
              change_font: (font) => on_change(curr_font_settings.copy_with(baselang_font: font)),
              curr_font_size: curr_font_settings.base_baselang_font_size,
              change_font_size: (size) => on_change(curr_font_settings.copy_with(base_baselang_font_size: size)),
              update_error: (error) => error_updater("baselang_font_size", error),
            ),
          ],
        ).toList(),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class FontDialog extends StatelessWidget {
  const FontDialog();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Language>(
      builder: (context, language) {
        _FontSettings curr_font_settings = _FontSettings.from_language(language);

        return EditDialog(
          title: "Fonts",
          initial_value: curr_font_settings,
          editor_builder: (curr_font_settings, on_change, update_errors) => _FontsEditor(
            language: language,
            curr_font_settings: curr_font_settings,
            on_change: on_change,
            update_errors: update_errors,
          ),
          on_confirm: (font_settings) => font_settings.save(context, curr_font_settings),
        );
      },
    );
  }
}
