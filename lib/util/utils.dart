import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/base_cubit.dart';
import 'package:dictionary_editor/cubits/database_cubit.dart';
import 'package:dictionary_editor/cubits/language_cubit.dart';
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/cubits/words_cubit.dart';
import 'package:dictionary_editor/objects/filter_settings.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/widgets/misc.dart';

List<DataCubit> get_data_cubits(BuildContext context) {
  return [
    BlocProvider.of<LettersCubit>(context),
    BlocProvider.of<PartsOfSpeechCubit>(context),
    BlocProvider.of<WordsCubit>(context),
  ];
}

Future update_cubits(BuildContext context) async {
  await BlocProvider.of<LanguageCubit>(context).update();
  List<DataCubit> data_cubits = get_data_cubits(context);
  for (DataCubit cubit in data_cubits) await cubit.update();
}

Future<String?> choose_file() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    dialogTitle: "Select database",
    type: FileType.custom,
    allowedExtensions: ["db"],
    lockParentWindow: true,
  );
  return result?.files.single.path;
}

Widget highlight_search_text(
  String text, {
  required BuildContext context,
  required FilterSettings filter_settings,
  required Settings settings,
  LetterInfo? letter_info,
  bool conlang = false,
  TextStyle? base_style,
  TextStyle? highlight_style,
}) {
  List<Match> matches =
      conlang ? settings.get_conlang_matches(text, filter_settings.conlang_search_string ?? '', letter_info!) : settings.get_baselang_matches(text, filter_settings.baselang_search_string ?? '');
  return highlight_text(
    context,
    matches,
    text,
    selectable: true,
    base_style: base_style,
    highlight_style: highlight_style,
  );
}

Future update_prev_file_preference(BuildContext context, String path) {
  return context.read<SettingsCubit>().update_setting((shared_preferences) => shared_preferences.setString(Settings.PREVIOUS_FILE_SETTING, path));
}

Future _open_database(BuildContext context, DatabaseCubit database_cubit) async {
  String? path = await choose_file();
  if (path != null) {
    await database_cubit.open_db(path);
    await update_prev_file_preference(context, path);
  }
}

Future open_database(BuildContext context) async {
  DatabaseCubit database_cubit = BlocProvider.of<DatabaseCubit>(context);
  if (database_cubit.state.has_changes) {
    await showDialog(
      context: context,
      builder: (context) => DiscardFileConfirmationDialog(
        on_confirm: () => _open_database(context, database_cubit),
      ),
    );
  } else
    await _open_database(context, database_cubit);
}

Future new_database(BuildContext context) async {
  DatabaseCubit database_cubit = BlocProvider.of<DatabaseCubit>(context);
  if (database_cubit.state.has_changes) {
    await showDialog(
      context: context,
      builder: (context) => DiscardFileConfirmationDialog(
        on_confirm: database_cubit.new_db,
      ),
    );
  } else
    await database_cubit.new_db();
}

String? ignore_string_parameter(String? param, String? field) => param == constants.IGNORED_STRING_VALUE ? field : param;

int? ignore_positive_int_parameter(int? param, int? field) => param != null && param < 0 ? field : param;

double? ignore_positive_double_parameter(double? param, double? field) => param != null && param < 0 ? field : param;

Uint8List? ignore_uint8list_parameter(List<int>? param, Uint8List? field) => param is Uint8List? ? param : field;

bool? ignore_bool_parameter(FutureOr<bool?> param, bool? field) => param is Future ? field : param;
