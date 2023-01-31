import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dictionary_editor/objects/settings.dart';

class SettingsCubit extends Cubit<Settings> {
  late SharedPreferences shared_preferences;
  late Future initial_settings_obtained;

  SettingsCubit() : super(const Settings()) {
    initial_settings_obtained = get_settings();
  }

  Future get_settings() async {
    shared_preferences = await SharedPreferences.getInstance();
    emit(
      Settings(
        theme: shared_preferences.getString(Settings.THEME_SETTING),
        previous_file: shared_preferences.getString(Settings.PREVIOUS_FILE_SETTING),
        edit_panel_width: shared_preferences.getDouble(Settings.EDIT_PANEL_WIDTH_SETTING),
        regex_search: shared_preferences.getBool(Settings.REGEX_SEARCH_SETTING),
        baselang_case_sensitive_search: shared_preferences.getBool(Settings.BASELANG_CASE_SENSITIVE_SEARCH_SETTING),
        conlang_normalized_search: shared_preferences.getBool(Settings.CONLANG_NORMALIZED_SEARCH_SETTING),
        conlang_case_sensitive_search: shared_preferences.getBool(Settings.CONLANG_CASE_SENSITIVE_SEARCH_SETTING),
      ),
    );
  }

  Future update_setting(Future Function(SharedPreferences shared_preferences) update_func) async {
    await initial_settings_obtained;
    await update_func(shared_preferences);
    await get_settings();
  }
}
