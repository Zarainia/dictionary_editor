import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/constants.dart' as constants;
import 'package:dictionary_editor/cubits/database_cubit.dart';
import 'package:dictionary_editor/cubits/undo_cubit.dart';
import 'package:dictionary_editor/dialogs/fonts.dart';
import 'package:dictionary_editor/dialogs/language.dart';
import 'package:dictionary_editor/dialogs/letters.dart';
import 'package:dictionary_editor/dialogs/pos.dart';
import 'package:dictionary_editor/dialogs/settings.dart';
import 'package:dictionary_editor/util/utils.dart';
import 'search.dart';

enum AppBarMenuOption { SETTINGS, LANGUAGE, FONT, POS, LETTERS }

class _AppBarMenuItem extends StatelessWidget {
  final AppBarMenuOption option;
  final IconData icon;
  final String name;

  const _AppBarMenuItem({required this.option, required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return MenuEntryItemWrapper(
      value: option,
      builder: (context, __) => Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Text(name),
        ],
      ),
    );
  }
}

class AppBarMenu extends StatelessWidget {
  const AppBarMenu();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppBarMenuOption.SETTINGS,
          child: _AppBarMenuItem(
            option: AppBarMenuOption.SETTINGS,
            icon: constants.SETTINGS_ICON,
            name: "Settings",
          ),
        ),
        PopupMenuItem(
          value: AppBarMenuOption.LANGUAGE,
          child: _AppBarMenuItem(
            option: AppBarMenuOption.LANGUAGE,
            icon: constants.LANGUAGE_ICON,
            name: "Language",
          ),
        ),
        PopupMenuItem(
          value: AppBarMenuOption.FONT,
          child: _AppBarMenuItem(
            option: AppBarMenuOption.FONT,
            icon: constants.FONT_ICON,
            name: "Font",
          ),
        ),
        PopupMenuItem(
          value: AppBarMenuOption.POS,
          child: _AppBarMenuItem(
            option: AppBarMenuOption.POS,
            icon: constants.PART_OF_SPEECH_ICON,
            name: "Parts of speech",
          ),
        ),
        PopupMenuItem(
          value: AppBarMenuOption.LETTERS,
          child: _AppBarMenuItem(
            option: AppBarMenuOption.LETTERS,
            icon: constants.LETTERS_ICON,
            name: "Letters",
          ),
        ),
      ],
      onSelected: (item) {
        switch (item) {
          case AppBarMenuOption.SETTINGS:
            show_settings_dialog(context);
            break;
          case AppBarMenuOption.LANGUAGE:
            show_language_dialog(context);
            break;
          case AppBarMenuOption.FONT:
            show_font_dialog(context);
            break;
          case AppBarMenuOption.POS:
            show_pos_dialog(context);
            break;
          case AppBarMenuOption.LETTERS:
            show_letters_dialog(context);
            break;
        }
      },
    );
  }
}

class AppBarButtons extends StatelessWidget {
  const AppBarButtons();

  @override
  Widget build(BuildContext outer_context) {
    return BlocBuilder<UndoCubit, UndoState>(
      builder: (context, undo_state) => Row(
        children: [
          Expanded(
            child: ZarainiaTheme.on_appbar_theme_provider(
              context,
              (context) => Row(
                children: [
                  IconButton(icon: Icon(Icons.note_add), onPressed: () => new_database(outer_context), tooltip: "New"),
                  IconButton(icon: Icon(Icons.folder_open), onPressed: () => open_database(outer_context), tooltip: "Open"),
                  BlocBuilder<DatabaseCubit, DatabaseState>(
                    builder: (context, database_state) => IconButton(
                        icon: Icon(Icons.save),
                        onPressed: ((undo_state.has_changes && database_state.has_changes) || database_state.path == null) ? () => context.read<DatabaseCubit>().save(outer_context) : null,
                        tooltip: "Save"),
                  ),
                  IconButton(icon: Icon(Icons.undo), onPressed: undo_state.can_undo ? context.read<UndoCubit>().undo : null, tooltip: "Undo"),
                  IconButton(icon: Icon(Icons.redo), onPressed: undo_state.can_redo ? context.read<UndoCubit>().redo : null, tooltip: "Redo"),
                ],
              ),
              bright_icons: true,
            ),
          ),
          const AppBarMenu(),
        ],
      ),
    );
  }
}

class AppBarWidgets extends StatelessWidget {
  const AppBarWidgets();

  @override
  Widget build(BuildContext context) {
    return Padding(
      child: Column(
        children: [
          const SearchFields(),
          const SizedBox(height: 10),
          const AppBarButtons(),
        ],
      ),
      padding: const EdgeInsets.only(top: 15, bottom: 10),
    );
  }
}
