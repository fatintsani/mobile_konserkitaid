import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:konserkita_mobile/l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: const Text('Bahasa Indonesia'),
            value: 'id',
            groupValue: localeProvider.locale.languageCode,
            onChanged: (value) {
              if (value != null) {
                localeProvider.setLocale(Locale(value));
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: localeProvider.locale.languageCode,
            onChanged: (value) {
              if (value != null) {
                localeProvider.setLocale(Locale(value));
              }
            },
          ),
        ],
      ),
    );
  }
}
