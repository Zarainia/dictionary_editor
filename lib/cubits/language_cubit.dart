import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/database/language_database.dart';
import 'package:dictionary_editor/objects/language.dart';
import 'undo_cubit.dart';

class LanguageCubit extends Cubit<Language> {
  LanguageDatabaseManager language_database = LanguageDatabaseManager();
  BuildContext context;
  UndoCubit undo_cubit;

  LanguageCubit(this.context)
      : undo_cubit = BlocProvider.of<UndoCubit>(context),
        super(const Language()) {
    update();
  }

  Future update() async => emit(await language_database.get_language());

  Future _edit_value(String key, dynamic value) async {
    return await language_database.update_value(key, value);
  }

  Future edit_value(String key, dynamic value) async {
    dynamic curr_value = state.to_json()[key];
    return await undo_cubit.add_action(
      UndoAction.typeless(
        name: "Update language setting",
        do_func: () => _edit_value(key, value),
        undo_func: () => _edit_value(key, curr_value),
        callback: update,
      ),
    );
  }

  Future _edit_values(Map<String, dynamic> values) async {
    return await Future.wait(values.entries.map((entry) => _edit_value(entry.key, entry.value)));
  }

  Future edit_values(Map<String, dynamic> values) async {
    Map<String, dynamic> curr_values = state.to_json();
    return await undo_cubit.add_action(
      UndoAction.typeless(
        name: "Update language setting",
        do_func: () => _edit_values(values),
        undo_func: () => _edit_values(curr_values),
        callback: update,
      ),
    );
  }
}
