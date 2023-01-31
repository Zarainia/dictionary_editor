import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synchronized/synchronized.dart';

class UndoAction<T, U> {
  String? name;
  FutureOr<T> Function([T? arg]) do_func;
  FutureOr<U> Function(T arg) undo_func;
  VoidCallback? callback;

  T? value;
  int progress = 0;

  UndoAction({this.name, required this.do_func, required this.undo_func, this.callback});

  static UndoAction<void, void> typeless({String? name, required FutureOr Function() do_func, required FutureOr Function() undo_func, VoidCallback? callback}) {
    return UndoAction<void, void>(name: name, do_func: (([_]) => do_func()), undo_func: ((_) => undo_func()), callback: callback);
  }

  Future<T> redo() async {
    assert(progress == 0);
    T result = await do_func(value);
    if (value == null) value = result;
    progress++;
    this.callback?.call();
    return result;
  }

  Future<U> undo() async {
    assert(progress == 1);
    U result = await undo_func(value as T);
    progress--;
    this.callback?.call();
    return result;
  }
}

class UndoState {
  final List<UndoAction> actions;
  final int position;

  UndoState({List<UndoAction>? actions, this.position = 0}) : actions = actions ?? [];

  UndoState with_added_action(UndoAction action) {
    return UndoState(actions: actions.sublist(0, position) + [action], position: position + 1);
  }

  UndoState with_position_change(int change) {
    int new_position = position + change;
    assert(new_position <= actions.length && new_position >= 0);
    return UndoState(actions: actions, position: new_position);
  }

  bool get can_redo => position < actions.length;

  bool get can_undo => actions.isNotEmpty && position > 0;

  bool get has_changes => can_undo;

  UndoAction get next_action => actions[position];

  UndoAction get prev_action => actions[position - 1];
}

class UndoCubit extends Cubit<UndoState> {
  Lock lock = Lock();

  UndoCubit() : super(UndoState());

  Future<T> add_action<T>(UndoAction action) async {
    return await lock.synchronized(() async {
      T result = await action.redo();
      emit(state.with_added_action(action));
      return result;
    });
  }

  Future<dynamic> undo() async {
    if (!state.can_undo) return;

    return await lock.synchronized(() async {
      UndoAction action = state.prev_action;
      dynamic result = await action.undo();
      emit(state.with_position_change(-1));
      return result;
    });
  }

  Future<dynamic> redo() async {
    if (!state.can_redo) return;

    return await lock.synchronized(() async {
      UndoAction action = state.next_action;
      dynamic result = await action.redo();
      emit(state.with_position_change(1));
      return result;
    });
  }

  void reset() {
    emit(UndoState());
  }
}
