import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/cubits/settings_cubit.dart';
import 'package:dictionary_editor/objects/settings.dart';

void show_settings_dialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const SettingsDialog());
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog();

  @override
  Widget build(BuildContext context) {
    return HeaderedButtonlessDialog(
      title: "Settings",
      child: BlocBuilder<SettingsCubit, Settings>(
        builder: (context, settings) => ListView(
          children: [
            DropdownButtonFormField(
              value: settings.theme,
              items: simpler_menu_items(context, ["light", "dark"]),
              onChanged: (String? theme) => context.read<SettingsCubit>().update_setting(
                    (shared_preferences) => shared_preferences.setString(Settings.THEME_SETTING, theme!),
                  ),
              decoration: TextFieldBorder(context: context, labelText: "Theme"),
              focusColor: Colors.transparent,
              isExpanded: true,
              selectedItemBuilder: simpler_selected_menu_items(["light", "dark"]),
            ),
          ],
          shrinkWrap: true,
        ),
      ),
    );
  }
}
