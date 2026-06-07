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

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get backupExportTitle => 'Export Backup';

  @override
  String get backupExportDesc => 'Accounts are encrypted with your password before export. Save the file to iCloud Drive, Google Drive, or any storage you use.';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupPasswordConfirm => 'Confirm password';

  @override
  String get backupPasswordMin => 'Minimum 8 characters';

  @override
  String get backupPasswordMismatch => 'Passwords do not match';

  @override
  String get backupExportShare => 'Export & Share';

  @override
  String get backupEncrypting => 'Encrypting...';

  @override
  String get backupNoAccounts => 'No accounts to export.';

  @override
  String get backupRestoreTitle => 'Restore Backup';

  @override
  String get backupRestoreDesc => 'Choose a .genauth backup file and enter the password used when exporting.';

  @override
  String get backupChooseFile => 'Choose backup file';

  @override
  String get backupDecrypting => 'Decrypting...';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupRestoreDialogTitle => 'Restore backup';

  @override
  String backupRestoreDialogContent(int count) {
    return 'Found $count account(s) in backup.\n\nReplace: removes all current accounts and uses backup.\nMerge: adds accounts from backup that don\'t exist yet.';
  }

  @override
  String get backupMerge => 'Merge';

  @override
  String get backupReplace => 'Replace';

  @override
  String backupRestoredSuccess(int count) {
    return 'Restored $count account(s).';
  }

  @override
  String backupInvalidFile(Object error) {
    return 'Invalid backup file: $error';
  }

  @override
  String get backupWrongPassword => 'Wrong password or corrupted file.';

  @override
  String backupExportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get githubLinkOpenFailed => 'Unable to open GitHub link.';

  @override
  String get openGithubRepository => 'Open GitHub repository';

  @override
  String get allRightsReserved => 'All rights reserved.';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }
}
