import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/database/database.dart';
import 'package:dictionary_editor/util/utils.dart';
import 'undo_cubit.dart';

class DatabaseState {
  final String? path;
  final bool loaded;
  final bool has_changes;

  const DatabaseState({this.path, this.loaded = false, this.has_changes = false});

  DatabaseState copy_with({String? path = constants.IGNORED_STRING_VALUE, bool? loaded, bool? has_changes}) {
    return DatabaseState(
      path: ignore_string_parameter(path, this.path),
      loaded: loaded ?? this.loaded,
      has_changes: has_changes ?? this.has_changes,
    );
  }
}

class DatabaseCubit extends Cubit<DatabaseState> {
  BuildContext context;
  DatabaseManager database_manager = DatabaseManager();
  StreamSubscription? database_change_subscription;
  UndoCubit undo_cubit;

  DatabaseCubit(this.context)
      : undo_cubit = BlocProvider.of<UndoCubit>(context),
        super(const DatabaseState()) {
    _load_previous_file();
  }

  Future _load_previous_file() async {
    SettingsCubit settings_cubit = BlocProvider.of<SettingsCubit>(context);
    await database_manager.db_is_open;
    await settings_cubit.initial_settings_obtained;
    String? previous_file_path = settings_cubit.state.previous_file;
    if (previous_file_path != null)
      await open_db(previous_file_path);
    else
      await finish_loading();
  }

  Future open_db(String path) async {
    update_state(DatabaseState(path: path));
    undo_cubit.reset();
    await database_manager.change_database(path);
    await finish_loading();
  }

  Future new_db() async {
    update_state(const DatabaseState(has_changes: true));
    undo_cubit.reset();
    await database_manager.open_new();
    await finish_loading();
  }

  Future _save_as_new(String path) async {
    await database_manager.save_as_new(path);
    update_state(DatabaseState(path: path, loaded: true, has_changes: false));
    await update_prev_file_preference(context, path);
  }

  Future save(BuildContext context) async {
    if (!undo_cubit.state.has_changes || !state.has_changes) return;

    if (state.path == null) {
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save dictionary',
        fileName: 'dictionary.db',
        type: FileType.custom,
        allowedExtensions: ["db"],
        lockParentWindow: true,
      );
      if (path != null) {
        File file = File(path);
        if (await file.exists())
          showDialog(
            context: context,
            builder: (context) => ConfirmationDialog(
              message: "Overwrite file?",
              contents: "File ${path} already exists. Are you sure you want to overwrite it?",
              on_confirm: () async {
                await file.delete();
                await _save_as_new(path);
              },
            ),
          );
        else
          await _save_as_new(path);
      }
    } else {
      await database_manager.persist();
      update_state(state.copy_with(has_changes: false));
    }
  }

  Future finish_loading() async {
    database_change_subscription?.cancel();
    database_change_subscription = database_manager.database.action_stream_controller.stream.listen((_) {
      if (!state.has_changes) update_state(state.copy_with(has_changes: true));
    });
    await update_cubits(context);
    update_state(state.copy_with(loaded: true));
  }

  void update_state(DatabaseState new_state) => emit(new_state);

  @override
  Future<void> close() {
    database_change_subscription?.cancel();
    return super.close();
  }
}
