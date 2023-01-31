import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/filter_settings_cubit.dart';
import 'package:dictionary_editor/cubits/pos_cubit.dart';
import 'package:dictionary_editor/objects/filter_settings.dart';
import 'package:dictionary_editor/theme.dart';

class FilterSettingsEditor extends StatelessWidget {
  final Widget Function(FilterSettingsCubit, FilterSettings) builder;

  const FilterSettingsEditor({required this.builder});

  @override
  Widget build(BuildContext context) {
    return ZarainiaTheme.off_appbar_theme_provider(
      context,
      (context) => PopoverButton(
        clickable_builder: (context, onclick) => ZarainiaTheme.on_appbar_theme_provider(
          context,
          (context) => IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: onclick,
            tooltip: "Filter",
          ),
          bright_icons: true,
        ),
        overlay_contents: PopoverContentsWrapper(
          header: Row(
            children: [
              Expanded(child: PopoverHeader(title: "Filter")),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => context.read<FilterSettingsCubit>().update(const FilterSettings()),
                tooltip: "Clear filters",
              ),
            ],
          ),
          body: BlocBuilder<FilterSettingsCubit, FilterSettings>(
            builder: (context, settings) => builder(context.read<FilterSettingsCubit>(), settings),
          ),
        ),
      ),
    );
  }
}

class IncludesFieldFilterSettingsBody extends StatefulWidget {
  final FilterSettingsCubit filter_settings_cubit;
  final FilterSettings settings;

  const IncludesFieldFilterSettingsBody(this.filter_settings_cubit, this.settings);

  @override
  _IncludesFieldFilterSettingsBodyState createState() => _IncludesFieldFilterSettingsBodyState();
}

class _IncludesFieldFilterSettingsBodyState extends State<IncludesFieldFilterSettingsBody> {
  bool expanded = false;

  Widget create_option(String name, bool? value, IncludesFieldFilter Function(IncludesFieldFilter included_fields, bool? val) updater, {Function(String)? on_search}) {
    ThemeColours theme_colours = get_theme_colours(context);
    TextStyle base_style = DefaultTextStyle.of(context).style;

    return Column(
      children: [
        CheckboxListTile(
          tristate: true,
          title: Text(name, style: base_style.copyWith(fontWeight: FontWeight.normal, fontSize: base_style.fontSize! * 0.9)),
          value: value,
          onChanged: (value) => widget.filter_settings_cubit.update(
            widget.settings.copy_with(included_fields: updater(widget.settings.included_fields, value)),
          ),
        ),
        if (value == true && on_search != null)
          Padding(
            child: SearchField(
              on_search: on_search,
              hint: "Search ${name.toLowerCase()}",
              hint_style: theme_colours.DEFAULT_INPUT_HINT_STYLE.copyWith(fontSize: theme_colours.DEFAULT_INPUT_HINT_STYLE.fontSize! * 0.9),
              style: theme_colours.BASELANG_STYLE,
            ),
            padding: const EdgeInsets.only(left: 15, right: 20, bottom: 15),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);
    IncludesFieldFilter included_fields = widget.settings.included_fields;
    int selected_fields =
        [included_fields.number, included_fields.pronunciation, included_fields.etymology, included_fields.notes, included_fields.translations, included_fields.audio].whereNotNull().length;

    return Column(
      children: [
        ListTile(
          title: expanded
              ? const Text("Includes")
              : Row(
                  children: [
                    const Text("Includes:"),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${selected_fields} fields included",
                        style: TextStyle(color: theme_colours.ACCENT_TEXT_COLOUR),
                      ),
                    ),
                  ],
                ),
          onTap: () {
            setState(() {
              expanded = !expanded;
            });
          },
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
        ),
        if (expanded)
          Padding(
            child: Column(
              children: [
                create_option("Number", included_fields.number, (included_fields, number) => included_fields.copy_with(number: number)),
                create_option(
                  "Pronunciation",
                  included_fields.pronunciation,
                  (included_fields, pronunciation) => included_fields.copy_with(pronunciation: pronunciation),
                  on_search: (pronunciation) => widget.filter_settings_cubit.update(
                    widget.settings.copy_with(pronunciation_search_string: pronunciation),
                  ),
                ),
                create_option(
                  "Etymology",
                  included_fields.etymology,
                  (included_fields, etymology) => included_fields.copy_with(etymology: etymology),
                  on_search: (etymology) => widget.filter_settings_cubit.update(
                    widget.settings.copy_with(etymology_search_string: etymology),
                  ),
                ),
                create_option(
                  "Notes",
                  included_fields.notes,
                  (included_fields, notes) => included_fields.copy_with(notes: notes),
                  on_search: (notes) => widget.filter_settings_cubit.update(
                    widget.settings.copy_with(notes_search_string: notes),
                  ),
                ),
                create_option("Translations", included_fields.translations, (included_fields, translations) => included_fields.copy_with(translations: translations)),
                create_option("Audio", included_fields.audio, (included_fields, audio) => included_fields.copy_with(audio: audio)),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            padding: const EdgeInsets.only(left: 20, bottom: 20),
          ),
      ],
      mainAxisSize: MainAxisSize.min,
    );
  }
}

class WordsFilterSettingsBody extends StatelessWidget {
  final FilterSettingsCubit filter_settings_cubit;
  final FilterSettings settings;

  const WordsFilterSettingsBody(this.filter_settings_cubit, this.settings);

  @override
  Widget build(BuildContext context) {
    Function(Set<int>) update_pos = (new_pos) => filter_settings_cubit.update(settings.copy_with(pos_ids: new_pos));

    return ListView(
      children: [
        IncludesFieldFilterSettingsBody(filter_settings_cubit, settings),
        BlocBuilder<PartsOfSpeechCubit, PartOfSpeechInfo>(
          builder: (context, pos) => MultiFilterSimpleSelectDialog<int>(
            item_name: "part of speech",
            item_name_plural: "parts of speech",
            curr_selections: settings.pos_ids,
            all_options: pos.pos.values.sortedBy((p) => p.name).map((p) => p.id).toList(),
            display_convertor: (pos_id) => pos.pos[pos_id]!.name,
            confirm_callback: update_pos,
          ),
        ),
      ],
      shrinkWrap: true,
    );
  }
}
