// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GenAuth';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get searchHint => 'Search Account...';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get lockapp => 'Lock App';

  @override
  String get authenticator => 'Authenticator';

  @override
  String get unlock => 'Unlock';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get aboutDescription => 'A secure TOTP/2FA authenticator powered by genotp-go.';

  @override
  String get noResults => 'No results';

  @override
  String get noAccountsYet => 'No accounts yet';

  @override
  String get tapToAddFirstAccount => 'Tap + to add your first account';

  @override
  String get addAccount => 'Add account';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String invalidQr(Object error) {
    return 'Invalid QR: $error';
  }

  @override
  String get accountLabel => 'Account (e.g. user@example.com)';

  @override
  String get issuerLabel => 'Issuer (e.g. Google)';

  @override
  String get requiredField => 'Required';

  @override
  String get secretKeyLabel => 'Secret key (Base32)';

  @override
  String get generateNewSecret => 'Generate new secret';

  @override
  String get algorithm => 'Algorithm';

  @override
  String get digits => 'Digits';

  @override
  String get hotpCounterBased => 'HOTP (counter-based)';

  @override
  String get defaultTotpTimeBased => 'Default is TOTP (time-based)';

  @override
  String get periodSeconds => 'Period (seconds)';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String removeAccount(Object accountName) {
    return 'Remove $accountName?';
  }

  @override
  String get nextCode => 'Next code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Welcome to GenAuth';

  @override
  String get onboardingDesc1 => 'Store your TOTP and HOTP codes safely in one place.';

  @override
  String get onboardingTitle2 => 'Add Accounts Quickly';

  @override
  String get onboardingDesc2 => 'Scan a QR code or add account details manually in seconds.';

  @override
  String get onboardingTitle3 => 'Protected Access';

  @override
  String get onboardingDesc3 => 'Your app is protected with device authentication before you enter.';
}
