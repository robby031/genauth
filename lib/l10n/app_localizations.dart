import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GenAuth'**
  String get appTitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Account...'**
  String get searchHint;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lockapp.
  ///
  /// In en, this message translates to:
  /// **'Lock App'**
  String get lockapp;

  /// No description provided for @authenticator.
  ///
  /// In en, this message translates to:
  /// **'Authenticator'**
  String get authenticator;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric'**
  String get unlock;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailed;

  /// No description provided for @deviceAuthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device does not support device authentication.'**
  String get deviceAuthUnsupported;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get indonesian;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A secure TOTP/2FA authenticator powered by genotp-go.'**
  String get aboutDescription;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYet;

  /// No description provided for @tapToAddFirstAccount.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first account'**
  String get tapToAddFirstAccount;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @scannerUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanner unavailable'**
  String get scannerUnavailableTitle;

  /// No description provided for @scannerUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The camera scanner could not be started. Please try again.'**
  String get scannerUnavailableMessage;

  /// No description provided for @scannerRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scannerRetry;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get manualEntry;

  /// No description provided for @invalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR: {error}'**
  String invalidQr(Object error);

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account (e.g. user@example.com)'**
  String get accountLabel;

  /// No description provided for @issuerLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuer (e.g. Google)'**
  String get issuerLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @secretKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret key (Base32)'**
  String get secretKeyLabel;

  /// No description provided for @generateNewSecret.
  ///
  /// In en, this message translates to:
  /// **'Generate new secret'**
  String get generateNewSecret;

  /// No description provided for @algorithm.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get algorithm;

  /// No description provided for @digits.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get digits;

  /// No description provided for @hotpCounterBased.
  ///
  /// In en, this message translates to:
  /// **'HOTP (counter-based)'**
  String get hotpCounterBased;

  /// No description provided for @defaultTotpTimeBased.
  ///
  /// In en, this message translates to:
  /// **'Default is TOTP (time-based)'**
  String get defaultTotpTimeBased;

  /// No description provided for @periodSeconds.
  ///
  /// In en, this message translates to:
  /// **'Period (seconds)'**
  String get periodSeconds;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @removeAccount.
  ///
  /// In en, this message translates to:
  /// **'Remove {accountName}?'**
  String removeAccount(Object accountName);

  /// No description provided for @nextCode.
  ///
  /// In en, this message translates to:
  /// **'Next code'**
  String get nextCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GenAuth'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Store your TOTP and HOTP codes safely in one place.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Add Accounts Quickly'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or add account details manually in seconds.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Protected Access'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Your app is protected with device authentication before you enter.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingGuideTitle1.
  ///
  /// In en, this message translates to:
  /// **'Add and Generate OTP'**
  String get onboardingGuideTitle1;

  /// No description provided for @onboardingGuideDesc1.
  ///
  /// In en, this message translates to:
  /// **'Add accounts by scanning QR or manual entry. GenAuth then generates OTP codes automatically on the home screen.'**
  String get onboardingGuideDesc1;

  /// No description provided for @onboardingGuideTitle2.
  ///
  /// In en, this message translates to:
  /// **'Find and Organize Accounts'**
  String get onboardingGuideTitle2;

  /// No description provided for @onboardingGuideDesc2.
  ///
  /// In en, this message translates to:
  /// **'Use search and tags to find accounts quickly, then reorder them to match your workflow.'**
  String get onboardingGuideDesc2;

  /// No description provided for @onboardingGuideTitle3.
  ///
  /// In en, this message translates to:
  /// **'Protect and Recover Data'**
  String get onboardingGuideTitle3;

  /// No description provided for @onboardingGuideDesc3.
  ///
  /// In en, this message translates to:
  /// **'Use lock, PIN, or Decoy PIN for protection, and keep backups ready with Backup & Restore.'**
  String get onboardingGuideDesc3;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingDone;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @googleAuthSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Authenticator'**
  String get googleAuthSectionTitle;

  /// No description provided for @googleAuthSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Import multi-account QR exports from Google Authenticator and generate compatible export QR codes from GenAuth.'**
  String get googleAuthSectionDesc;

  /// No description provided for @googleAuthImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import from QR'**
  String get googleAuthImportAction;

  /// No description provided for @googleAuthExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export as QR'**
  String get googleAuthExportAction;

  /// No description provided for @googleAuthNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts available for Google Authenticator export.'**
  String get googleAuthNoAccounts;

  /// No description provided for @googleAuthExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to Google Authenticator'**
  String get googleAuthExportTitle;

  /// No description provided for @googleAuthExportHint.
  ///
  /// In en, this message translates to:
  /// **'Open Google Authenticator on the other device, choose Import accounts, then scan each QR in order.'**
  String get googleAuthExportHint;

  /// No description provided for @googleAuthExportIntro.
  ///
  /// In en, this message translates to:
  /// **'This export includes {count} account(s). If needed, GenAuth will split them into several QR codes that Google Authenticator can read.'**
  String googleAuthExportIntro(int count);

  /// No description provided for @googleAuthBatchLabel.
  ///
  /// In en, this message translates to:
  /// **'QR {current} of {total}'**
  String googleAuthBatchLabel(int current, int total);

  /// No description provided for @googleAuthBatchAccounts.
  ///
  /// In en, this message translates to:
  /// **'{count} account(s) in this QR'**
  String googleAuthBatchAccounts(int count);

  /// No description provided for @googleAuthTableQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get googleAuthTableQr;

  /// No description provided for @googleAuthTableIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get googleAuthTableIssuer;

  /// No description provided for @googleAuthTableAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get googleAuthTableAccount;

  /// No description provided for @googleAuthTableType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get googleAuthTableType;

  /// No description provided for @backupExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get backupExportTitle;

  /// No description provided for @backupExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Accounts are encrypted with your password before export. Save the file to iCloud Drive, Google Drive, or any storage you use.'**
  String get backupExportDesc;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPassword;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get backupPasswordConfirm;

  /// No description provided for @backupPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get backupPasswordMin;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get backupPasswordMismatch;

  /// No description provided for @backupExportShare.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get backupExportShare;

  /// No description provided for @backupEncrypting.
  ///
  /// In en, this message translates to:
  /// **'Encrypting...'**
  String get backupEncrypting;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'GenAuth Backup'**
  String get backupShareSubject;

  /// No description provided for @backupSavedFile.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully: {fileName}'**
  String backupSavedFile(Object fileName);

  /// No description provided for @backupNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts to export.'**
  String get backupNoAccounts;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a .genauth backup file and enter the password used when exporting.'**
  String get backupRestoreDesc;

  /// No description provided for @backupChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get backupChooseFile;

  /// No description provided for @backupDecrypting.
  ///
  /// In en, this message translates to:
  /// **'Decrypting...'**
  String get backupDecrypting;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @backupRestoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestoreDialogTitle;

  /// No description provided for @backupRestoreDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Found {count} account(s) in backup.\n\nReplace: removes all current accounts and uses backup.\nMerge: adds accounts from backup that don\'t exist yet.'**
  String backupRestoreDialogContent(int count);

  /// No description provided for @backupMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get backupMerge;

  /// No description provided for @backupReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get backupReplace;

  /// No description provided for @backupRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} account(s).'**
  String backupRestoredSuccess(int count);

  /// No description provided for @backupInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file: {error}'**
  String backupInvalidFile(Object error);

  /// No description provided for @backupWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or corrupted file.'**
  String get backupWrongPassword;

  /// No description provided for @googleLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to GenAuth'**
  String get googleLoginTitle;

  /// No description provided for @googleLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your Google account to set up GenAuth on this device.'**
  String get googleLoginSubtitle;

  /// No description provided for @googleLoginBenefit1.
  ///
  /// In en, this message translates to:
  /// **'Tied to your Google identity — easy to recognize this device later.'**
  String get googleLoginBenefit1;

  /// No description provided for @googleLoginBenefit2.
  ///
  /// In en, this message translates to:
  /// **'Enables optional encrypted backup to your private Google Drive folder.'**
  String get googleLoginBenefit2;

  /// No description provided for @googleLoginBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Daily unlock still uses biometrics or PIN — your secrets stay on this device.'**
  String get googleLoginBenefit3;

  /// No description provided for @googleLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleLoginCta;

  /// No description provided for @googleLoginInProgress.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get googleLoginInProgress;

  /// No description provided for @googleLoginDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'GenAuth only reads your basic profile (email, name, photo). It cannot access your other Google data.'**
  String get googleLoginDisclaimer;

  /// No description provided for @driveBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Backup'**
  String get driveBackupTitle;

  /// No description provided for @driveBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to upload encrypted backups to a hidden app folder in your Drive.'**
  String get driveBackupDesc;

  /// No description provided for @driveBackupSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get driveBackupSignIn;

  /// No description provided for @driveBackupSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get driveBackupSignOut;

  /// No description provided for @driveBackupSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String driveBackupSignedInAs(Object email);

  /// No description provided for @driveBackupUpload.
  ///
  /// In en, this message translates to:
  /// **'Backup to Drive'**
  String get driveBackupUpload;

  /// No description provided for @driveBackupUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get driveBackupUploading;

  /// No description provided for @driveBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from Drive'**
  String get driveBackupRestore;

  /// No description provided for @driveBackupLoadingList.
  ///
  /// In en, this message translates to:
  /// **'Loading backups...'**
  String get driveBackupLoadingList;

  /// No description provided for @driveBackupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backups found on Drive yet.'**
  String get driveBackupEmpty;

  /// No description provided for @driveBackupPickFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup'**
  String get driveBackupPickFile;

  /// No description provided for @driveBackupUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {fileName} to Drive.'**
  String driveBackupUploadSuccess(Object fileName);

  /// No description provided for @driveBackupSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {error}'**
  String driveBackupSignInFailed(Object error);

  /// No description provided for @driveBackupUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Drive upload failed: {error}'**
  String driveBackupUploadFailed(Object error);

  /// No description provided for @driveBackupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Drive restore failed: {error}'**
  String driveBackupRestoreFailed(Object error);

  /// No description provided for @driveAutoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto backup'**
  String get driveAutoBackupTitle;

  /// No description provided for @driveAutoBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically uploads an encrypted backup to Drive when the selected interval has elapsed and the app is opened again.'**
  String get driveAutoBackupDesc;

  /// No description provided for @driveAutoBackupEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable auto backup'**
  String get driveAutoBackupEnable;

  /// No description provided for @driveAutoBackupInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get driveAutoBackupInterval;

  /// No description provided for @driveAutoBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get driveAutoBackupDaily;

  /// No description provided for @driveAutoBackupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get driveAutoBackupWeekly;

  /// No description provided for @driveAutoBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Auto backup password'**
  String get driveAutoBackupPassword;

  /// No description provided for @driveAutoBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Auto backup settings saved.'**
  String get driveAutoBackupSaved;

  /// No description provided for @driveAutoBackupDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto backup disabled.'**
  String get driveAutoBackupDisabled;

  /// No description provided for @driveAutoBackupPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Auto backup password must be at least 8 characters.'**
  String get driveAutoBackupPasswordMin;

  /// No description provided for @driveBackupConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete backup?'**
  String get driveBackupConfirmDeleteTitle;

  /// No description provided for @driveBackupConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove {fileName} from your Drive? This cannot be undone.'**
  String driveBackupConfirmDelete(Object fileName);

  /// No description provided for @driveBackupDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get driveBackupDelete;

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String backupExportFailed(Object error);

  /// No description provided for @accountsImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} account(s).'**
  String accountsImported(int count);

  /// No description provided for @accountsAlreadyImported.
  ///
  /// In en, this message translates to:
  /// **'All scanned accounts are already in GenAuth.'**
  String get accountsAlreadyImported;

  /// No description provided for @pinEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get pinEnterTitle;

  /// No description provided for @pinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get pinSetupTitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pinConfirmTitle;

  /// No description provided for @pinSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a 6-digit PIN as a backup unlock method'**
  String get pinSetupDesc;

  /// No description provided for @pinConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again to confirm'**
  String get pinConfirmDesc;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get pinWrong;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @pinSaved.
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully'**
  String get pinSaved;

  /// No description provided for @pinRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get pinRemoved;

  /// No description provided for @usePin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get usePin;

  /// No description provided for @setPinOption.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPinOption;

  /// No description provided for @removePinOption.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePinOption;

  /// No description provided for @setPanicPinOption.
  ///
  /// In en, this message translates to:
  /// **'Set Decoy PIN'**
  String get setPanicPinOption;

  /// No description provided for @removePanicPinOption.
  ///
  /// In en, this message translates to:
  /// **'Remove Decoy PIN'**
  String get removePanicPinOption;

  /// No description provided for @panicPinOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency decoy-vault PIN'**
  String get panicPinOptionSubtitle;

  /// No description provided for @panicPinRemoved.
  ///
  /// In en, this message translates to:
  /// **'Decoy PIN removed'**
  String get panicPinRemoved;

  /// No description provided for @panicPinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Decoy PIN'**
  String get panicPinSetupTitle;

  /// No description provided for @panicPinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Decoy PIN'**
  String get panicPinConfirmTitle;

  /// No description provided for @panicPinSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'This emergency PIN opens a decoy vault when used'**
  String get panicPinSetupDesc;

  /// No description provided for @panicPinConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the same Decoy PIN again to confirm'**
  String get panicPinConfirmDesc;

  /// No description provided for @panicPinSaved.
  ///
  /// In en, this message translates to:
  /// **'Decoy PIN set successfully'**
  String get panicPinSaved;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @auditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLogTitle;

  /// No description provided for @auditLogMenu.
  ///
  /// In en, this message translates to:
  /// **'Audit Activity'**
  String get auditLogMenu;

  /// No description provided for @auditLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity has been recorded yet.'**
  String get auditLogEmpty;

  /// No description provided for @auditLogClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all logs'**
  String get auditLogClearAll;

  /// No description provided for @auditLogClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear audit logs?'**
  String get auditLogClearConfirmTitle;

  /// No description provided for @auditLogClearConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove all local audit records.'**
  String get auditLogClearConfirmDesc;

  /// No description provided for @auditLogPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN first before clearing audit logs.'**
  String get auditLogPinRequired;

  /// No description provided for @auditLogStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get auditLogStatus;

  /// No description provided for @auditLogDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get auditLogDetail;

  /// No description provided for @auditLogMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get auditLogMetadata;

  /// No description provided for @auditLogCleared.
  ///
  /// In en, this message translates to:
  /// **'Audit logs cleared'**
  String get auditLogCleared;

  /// No description provided for @privacyPolicyMenu.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyMenu;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy URL is not configured yet. Set it in lib/utils/app_links.dart.'**
  String get privacyPolicyNotConfigured;

  /// No description provided for @privacyPolicyInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy URL is invalid. Please use a valid http/https URL.'**
  String get privacyPolicyInvalidUrl;

  /// No description provided for @privacyPolicyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load privacy policy page. Please try again later.'**
  String get privacyPolicyLoadFailed;

  /// No description provided for @privacyPolicyOpenExternalHint.
  ///
  /// In en, this message translates to:
  /// **'For this platform, privacy policy opens in the system browser view.'**
  String get privacyPolicyOpenExternalHint;

  /// No description provided for @privacyPolicyOpenExternal.
  ///
  /// In en, this message translates to:
  /// **'Open Privacy Policy'**
  String get privacyPolicyOpenExternal;

  /// No description provided for @termsConditionsMenu.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsMenu;

  /// No description provided for @termsConditionsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions URL is not configured yet. Set it in lib/utils/app_links.dart.'**
  String get termsConditionsNotConfigured;

  /// No description provided for @termsConditionsInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions URL is invalid. Please use a valid http/https URL.'**
  String get termsConditionsInvalidUrl;

  /// No description provided for @termsConditionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Terms & Conditions page. Please try again later.'**
  String get termsConditionsLoadFailed;

  /// No description provided for @drawerSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get drawerSectionSecurity;

  /// No description provided for @drawerSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data and Privacy'**
  String get drawerSectionData;

  /// No description provided for @drawerSectionApp.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get drawerSectionApp;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTag;

  /// No description provided for @editTags.
  ///
  /// In en, this message translates to:
  /// **'Edit Tags'**
  String get editTags;

  /// No description provided for @tagDomainHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: add domain mapping tags like domain:github.com or host:accounts.google.com for Android OTP autofill.'**
  String get tagDomainHint;

  /// No description provided for @tagHint.
  ///
  /// In en, this message translates to:
  /// **'Tag name...'**
  String get tagHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @githubLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open GitHub link.'**
  String get githubLinkOpenFailed;

  /// No description provided for @openGithubRepository.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub repository'**
  String get openGithubRepository;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get profileRefresh;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileSectionGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get profileSectionGoogleAccount;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileGivenName.
  ///
  /// In en, this message translates to:
  /// **'Given name'**
  String get profileGivenName;

  /// No description provided for @profileFamilyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get profileFamilyName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get profileLocale;

  /// No description provided for @profileGoogleId.
  ///
  /// In en, this message translates to:
  /// **'Google ID'**
  String get profileGoogleId;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get profileNotAvailable;

  /// No description provided for @profileSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to view your profile.'**
  String get profileSignInPrompt;

  /// No description provided for @autofillServiceMenu.
  ///
  /// In en, this message translates to:
  /// **'Autofill Service'**
  String get autofillServiceMenu;

  /// No description provided for @autofillServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable GenAuth OTP autofill in Android settings'**
  String get autofillServiceSubtitle;

  /// No description provided for @autofillServiceOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Android Autofill settings on this device.'**
  String get autofillServiceOpenFailed;

  /// No description provided for @autofillDomainMappedStatus.
  ///
  /// In en, this message translates to:
  /// **'Autofill domain mapped'**
  String get autofillDomainMappedStatus;

  /// No description provided for @autofillDomainNotMappedStatus.
  ///
  /// In en, this message translates to:
  /// **'Autofill domain not mapped'**
  String get autofillDomainNotMappedStatus;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'id': return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
