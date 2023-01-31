import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/filter_settings_cubit.dart';
import 'package:dictionary_editor/cubits/language_cubit.dart';
import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/objects/language.dart';
import 'package:dictionary_editor/objects/settings.dart';
import 'package:dictionary_editor/theme.dart';
import 'package:dictionary_editor/widgets/filter.dart';

class SearchFields extends StatelessWidget {
  const SearchFields();

  @override
  Widget build(BuildContext context) {
    return ZarainiaTheme.on_appbar_theme_provider(
      context,
      (context) {
        ThemeColours theme_colours = get_theme_colours(context);

        return BlocBuilder<LanguageCubit, Language>(
          builder: (context, language) => Row(
            children: [
              Expanded(
                child: SearchField(
                  on_search: (search_text) => context.read<FilterSettingsCubit>().update_setting(
                        (settings) => settings.copy_with(conlang_search_string: empty_null(search_text)),
                      ),
                  style: theme_colours.LARGER_CONLANG_STYLE,
                  hint: "Search ${language.conlang_name}",
                  hint_style: theme_colours.DEFAULT_INPUT_HINT_STYLE,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SearchField(
                  on_search: (search_text) => context.read<FilterSettingsCubit>().update_setting(
                        (settings) => settings.copy_with(baselang_search_string: empty_null(search_text)),
                      ),
                  style: theme_colours.LARGER_BASELANG_STYLE,
                  hint: "Search ${language.baselang_name}",
                  hint_style: theme_colours.DEFAULT_INPUT_HINT_STYLE,
                ),
              ),
              const SizedBox(width: 10),
              const FilterSettingsEditor(builder: WordsFilterSettingsBody.new),
              const SearchSettingsEditor(),
            ],
          ),
        );
      },
      bright_icons: true,
    );
  }
}

class SearchSettingsBody extends StatelessWidget {
  const SearchSettingsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, Settings>(
      builder: (context, settings) => BlocBuilder<LanguageCubit, Language>(
        builder: (context, language) => ListView(
          children: [
            CheckboxListTile(
              title: Text("Regex search"),
              value: settings.regex_search,
              onChanged: (bool? new_state) => context.read<SettingsCubit>().update_setting((shared_preferences) => shared_preferences.setBool(Settings.REGEX_SEARCH_SETTING, new_state!)),
            ),
            CheckboxListTile(
              title: Text("${language.conlang_name} normalized"),
              value: settings.conlang_normalized_search,
              onChanged: (bool? new_state) => context.read<SettingsCubit>().update_setting((shared_preferences) async {
                await shared_preferences.setBool(Settings.CONLANG_NORMALIZED_SEARCH_SETTING, new_state!);
                if (new_state) await shared_preferences.setBool(Settings.CONLANG_CASE_SENSITIVE_SEARCH_SETTING, false);
              }),
            ),
            if (!settings.conlang_normalized_search)
              CheckboxListTile(
                title: Text("${language.conlang_name} case sensitive"),
                value: settings.conlang_case_sensitive_search,
                onChanged: (bool? new_state) =>
                    context.read<SettingsCubit>().update_setting((shared_preferences) => shared_preferences.setBool(Settings.CONLANG_CASE_SENSITIVE_SEARCH_SETTING, new_state!)),
              ),
            CheckboxListTile(
              title: Text("${language.baselang_name} case sensitive"),
              value: settings.baselang_case_sensitive_search,
              onChanged: (bool? new_state) =>
                  context.read<SettingsCubit>().update_setting((shared_preferences) => shared_preferences.setBool(Settings.BASELANG_CASE_SENSITIVE_SEARCH_SETTING, new_state!)),
            ),
          ],
          shrinkWrap: true,
        ),
      ),
    );
  }
}

class SearchSettingsEditor extends StatelessWidget {
  const SearchSettingsEditor();

  @override
  Widget build(BuildContext context) {
    return ZarainiaTheme.off_appbar_theme_provider(
      context,
      (context) => PopoverButton(
        clickable_builder: (context, onclick) => ZarainiaTheme.on_appbar_theme_provider(
          context,
          (context) => IconButton(icon: Icon(Icons.settings), onPressed: onclick, tooltip: "Search settings"),
          bright_icons: true,
        ),
        overlay_contents: const PopoverContentsWrapper(
          header: PopoverHeader(title: "Search settings"),
          body: SearchSettingsBody(),
        ),
      ),
    );
  }
}
