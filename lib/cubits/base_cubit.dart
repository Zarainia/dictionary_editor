import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/cubits/undo_cubit.dart';
import 'package:dictionary_editor/objects/base.dart';

abstract class DataCubit<Output, T, IDType> extends Cubit<Output> {
  String entry_type = "data";

  BuildContext context;
  UndoCubit undo_cubit;

  DataCubit(this.context, super.initialState) : undo_cubit = BlocProvider.of<UndoCubit>(context);

  T? get_entry(IDType id);

  String get_entry_name(T entry) => "data";

  IDType get_entry_id(T entry);

  Map<String, dynamic> get_entry_full_json(T entry);

  Map<String, dynamic> get_entry_edit_json(T entry) => get_entry_full_json(entry);

  FutureOr update();

  FutureOr<T> insert_(T entry);

  Future<T> insert(T entry) async {
    return await undo_cubit.add_action(
      UndoAction(
        name: "Add ${entry_type}",
        do_func: ([inserted_entry]) => insert_(inserted_entry ?? entry),
        undo_func: (entry) => delete_(get_entry_id(entry)),
        callback: update,
      ),
    );
  }

  FutureOr edit_(IDType id, Map<String, dynamic> updates);

  Future edit(IDType id, Map<String, dynamic> updates) async {
    T entry = get_entry(id)!;
    return await undo_cubit.add_action(
      UndoAction.typeless(
        name: "Edit ${get_entry_name(entry)}",
        do_func: () => edit_(id, updates),
        undo_func: () => edit_(id, get_entry_edit_json(entry)),
        callback: update,
      ),
    );
  }

  Future edit_column(IDType id, String column, dynamic value) {
    return edit(id, {column: value});
  }

  FutureOr delete_(IDType id);

  Future delete(IDType id) async {
    T entry = get_entry(id)!;
    return undo_cubit.add_action(
      UndoAction.typeless(
        name: "Delete ${get_entry_name(entry)}",
        do_func: () => delete_(id),
        undo_func: () => insert_(entry),
        callback: update,
      ),
    );
  }
}

abstract class DatabaseItemCubit<Output, T extends DatabaseItem, IDType> extends DataCubit<Output, T, IDType> {
  DatabaseItemCubit(super.context, super.initialState);

  @override
  Map<String, dynamic> get_entry_full_json(T entry) => entry.to_json();

  @override
  Map<String, dynamic> get_entry_edit_json(T entry) => entry.to_edit_json();
}

abstract class IDIdentifiableCubit<Output, T extends IDIdentifiable> extends DatabaseItemCubit<Output, T, int> {
  IDIdentifiableCubit(super.context, super.initialState);

  int get_entry_id(T entry) => entry.id;

  T verify_inserted_entry_(T inserted, int id) {
    assert(!inserted.is_new && inserted.id == id);
    return inserted;
  }
}
