import 'package:flutter/material.dart';

import 'package:context_menus/context_menus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/database_cubit.dart';
import 'package:dictionary_editor/cubits/filter_settings_cubit.dart';
import 'package:dictionary_editor/cubits/language_cubit.dart';
import 'package:dictionary_editor/cubits/letters_cubit.dart';
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/cubits/undo_cubit.dart';
import 'package:dictionary_editor/cubits/word_list_cubit.dart';
import 'package:dictionary_editor/cubits/words_cubit.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/pages/main.dart';
import 'package:dictionary_editor/widgets/page.dart';
import 'package:dictionary_editor/widgets/shortcuts.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(lazy: false, create: (_) => UndoCubit()),
        BlocProvider(lazy: false, create: (_) => SettingsCubit()),
        BlocProvider(lazy: false, create: (_) => FilterSettingsCubit()),
        BlocProvider(lazy: false, create: (context) => LanguageCubit(context)),
        BlocProvider(lazy: false, create: (context) => LettersCubit(context)),
        BlocProvider(lazy: false, create: (context) => PartsOfSpeechCubit(context)),
        BlocProvider(lazy: false, create: (context) => WordsCubit(context)),
        BlocProvider(lazy: false, create: (context) => WordListCubit(context)),
        BlocProvider(lazy: false, create: (context) => DatabaseCubit(context)),
      ],
      child: BlocBuilder<SettingsCubit, Settings>(
        builder: (context, settings) => AppThemeProvider(
          theme: settings.theme,
          primary_colour: null,
          secondary_colour: null,
          builder: (context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: get_theme_colours(context).theme,
              home: ShortcutsWrapper(
                child: ContextMenuOverlay(
                  child: MyHomePage(settings: settings),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Settings settings;

  const MyHomePage({super.key, required this.settings});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MainPage(
      child: BlocBuilder<DatabaseCubit, DatabaseState>(
        builder: (context, database_state) {
          if (!database_state.loaded) return const LoadingIndicator();
          return const MainLayout();
        },
      ),
    );
  }
}
