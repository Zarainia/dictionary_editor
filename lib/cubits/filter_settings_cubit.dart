import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dictionary_editor/objects/filter_settings.dart';

class FilterSettingsCubit extends Cubit<FilterSettings> {
  FilterSettingsCubit() : super(const FilterSettings());

  void update(FilterSettings settings) => emit(settings);

  void update_setting(FilterSettings Function(FilterSettings settings) get_settings) => update(get_settings(state));
}
