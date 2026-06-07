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
  String get onboardingGuideTitle1 => 'Add and Generate OTP';

  @override
  String get onboardingGuideDesc1 => 'Add accounts by scanning QR or manual entry. GenAuth then generates OTP codes automatically on the home screen.';

  @override
  String get onboardingGuideTitle2 => 'Find and Organize Accounts';

  @override
  String get onboardingGuideDesc2 => 'Use search and tags to find accounts quickly, then reorder them to match your workflow.';

  @override
  String get onboardingGuideTitle3 => 'Protect and Recover Data';

  @override
  String get onboardingGuideDesc3 => 'Use lock, PIN, or Panic PIN for protection, and keep backups ready with Backup & Restore.';

  @override
  String get onboardingDone => 'Done';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get googleAuthSectionTitle => 'Google Authenticator';

  @override
  String get googleAuthSectionDesc => 'Import multi-account QR exports from Google Authenticator and generate compatible export QR codes from GenAuth.';

  @override
  String get googleAuthImportAction => 'Import from QR';

  @override
  String get googleAuthExportAction => 'Export as QR';

  @override
  String get googleAuthNoAccounts => 'No accounts available for Google Authenticator export.';

  @override
  String get googleAuthExportTitle => 'Export to Google Authenticator';

  @override
  String get googleAuthExportHint => 'Open Google Authenticator on the other device, choose Import accounts, then scan each QR in order.';

  @override
  String googleAuthExportIntro(int count) {
    return 'This export includes $count account(s). If needed, GenAuth will split them into several QR codes that Google Authenticator can read.';
  }

  @override
  String googleAuthBatchLabel(int current, int total) {
    return 'QR $current of $total';
  }

  @override
  String googleAuthBatchAccounts(int count) {
    return '$count account(s) in this QR';
  }

  @override
  String get googleAuthTableQr => 'QR';

  @override
  String get googleAuthTableIssuer => 'Issuer';

  @override
  String get googleAuthTableAccount => 'Account';

  @override
  String get googleAuthTableType => 'Type';

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
  String get backupShareSubject => 'GenAuth Backup';

  @override
  String backupSavedPath(Object fileName) {
    return 'Backup saved: Files -> On My iPhone -> GenAuth -> $fileName';
  }

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
  String accountsImported(int count) {
    return 'Imported $count account(s).';
  }

  @override
  String get accountsAlreadyImported => 'All scanned accounts are already in GenAuth.';

  @override
  String get pinEnterTitle => 'Enter PIN';

  @override
  String get pinSetupTitle => 'Set PIN';

  @override
  String get pinConfirmTitle => 'Confirm PIN';

  @override
  String get pinSetupDesc => 'Set a 6-digit PIN as a backup unlock method';

  @override
  String get pinConfirmDesc => 'Enter the same PIN again to confirm';

  @override
  String get pinWrong => 'Wrong PIN. Try again.';

  @override
  String get pinMismatch => 'PINs do not match. Try again.';

  @override
  String get pinSaved => 'PIN set successfully';

  @override
  String get pinRemoved => 'PIN removed';

  @override
  String get usePin => 'Use PIN';

  @override
  String get setPinOption => 'Set PIN';

  @override
  String get removePinOption => 'Remove PIN';

  @override
  String get setPanicPinOption => 'Set Panic PIN';

  @override
  String get removePanicPinOption => 'Remove Panic PIN';

  @override
  String get panicPinOptionSubtitle => 'Emergency self-destruct PIN';

  @override
  String get panicPinRemoved => 'Panic PIN removed';

  @override
  String get panicPinSetupTitle => 'Set Panic PIN';

  @override
  String get panicPinConfirmTitle => 'Confirm Panic PIN';

  @override
  String get panicPinSetupDesc => 'This emergency PIN will wipe all OTP data when used';

  @override
  String get panicPinConfirmDesc => 'Enter the same Panic PIN again to confirm';

  @override
  String get panicPinSaved => 'Panic PIN set successfully';

  @override
  String get panicCorruptedTitle => 'Database Error';

  @override
  String get panicCorruptedDesc => 'The app cannot load local data due to a storage integrity failure.';

  @override
  String get panicCorruptedHelp => 'Please restore from an available backup or reinstall the application.';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get close => 'Close';

  @override
  String get auditLogTitle => 'Audit Log';

  @override
  String get auditLogMenu => 'Audit Activity';

  @override
  String get auditLogEmpty => 'No activity has been recorded yet.';

  @override
  String get auditLogClearAll => 'Clear all logs';

  @override
  String get auditLogClearConfirmTitle => 'Clear audit logs?';

  @override
  String get auditLogClearConfirmDesc => 'This will permanently remove all local audit records.';

  @override
  String get auditLogStatus => 'Status';

  @override
  String get auditLogDetail => 'Detail';

  @override
  String get auditLogMetadata => 'Metadata';

  @override
  String get auditLogCleared => 'Audit logs cleared';

  @override
  String get privacyPolicyMenu => 'Privacy Policy';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyNotConfigured => 'Privacy policy URL is not configured yet. Set it in lib/utils/app_links.dart.';

  @override
  String get privacyPolicyInvalidUrl => 'Privacy policy URL is invalid. Please use a valid http/https URL.';

  @override
  String get privacyPolicyLoadFailed => 'Failed to load privacy policy page. Please try again later.';

  @override
  String get privacyPolicyOpenExternalHint => 'For this platform, privacy policy opens in the system browser view.';

  @override
  String get privacyPolicyOpenExternal => 'Open Privacy Policy';

  @override
  String get drawerSectionSecurity => 'Security';

  @override
  String get drawerSectionData => 'Data and Privacy';

  @override
  String get drawerSectionApp => 'Application';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add';

  @override
  String get editTags => 'Edit Tags';

  @override
  String get tagHint => 'Tag name...';

  @override
  String get done => 'Done';

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
