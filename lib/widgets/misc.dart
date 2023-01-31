import 'package:flutter/material.dart';

import 'package:zarainia_utils/zarainia_utils.dart';

import 'package:dictionary_editor/theme.dart';

class ListEndAddButton extends StatelessWidget {
  VoidCallback on_click;
  String tooltip;

  ListEndAddButton({required this.on_click, this.tooltip = "Add"});

  @override
  Widget build(BuildContext context) {
    ThemeColours theme_colours = get_theme_colours(context);

    return Padding(
      child: Tooltip(
        child: OutlinedButton(
          child: Icon(Icons.add, color: theme_colours.ICON_COLOUR),
          onPressed: on_click,
        ),
        message: tooltip,
      ),
      padding: EdgeInsets.only(top: 20),
    );
  }
}

class DiscardFileConfirmationDialog extends StatelessWidget {
  final VoidCallback on_confirm;

  const DiscardFileConfirmationDialog({required this.on_confirm});

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      message: "Discard changes?",
      contents: "You have unsaved changes. Are you sure you want to discard them?",
      confirm_button_text: "Discard",
      on_confirm: on_confirm,
    );
  }
}
