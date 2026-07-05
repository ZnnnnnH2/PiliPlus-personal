import 'package:flutter/material.dart';

TextStyle settingTitleStyle(ThemeData theme, {Color? color}) =>
    theme.textTheme.titleMedium!.copyWith(color: color);

TextStyle settingSubtitleStyle(ThemeData theme) =>
    theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.outline);
