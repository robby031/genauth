import 'package:flutter/widgets.dart';
import 'package:genauth/l10n/app_localizations.dart';

extension LocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
