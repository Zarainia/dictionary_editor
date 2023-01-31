import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keymap/keymap.dart';

import 'package:dictionary_editor/cubits/database_cubit.dart';
import 'package:dictionary_editor/cubits/undo_cubit.dart';

class ShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const ShortcutsWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return KeyboardWidget(
      bindings: [
        KeyAction(LogicalKeyboardKey.keyZ, isControlPressed: true, "Undo", () => context.read<UndoCubit>().undo()),
        KeyAction(LogicalKeyboardKey.keyY, isControlPressed: true, "Redo", () => context.read<UndoCubit>().redo()),
        KeyAction(LogicalKeyboardKey.keyS, isControlPressed: true, "Save", () => context.read<DatabaseCubit>().save(context)),
      ],
      child: child,
    );
  }
}
