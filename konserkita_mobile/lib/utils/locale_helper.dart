import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class LocaleHelper {
  static String getLocalizedText(BuildContext context, String? enText, String idText) {
    final locale = context.read<LocaleProvider>().locale;
    if (locale.languageCode == 'en' && enText != null && enText.isNotEmpty) {
      return enText;
    }
    return idText;
  }
}
