// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'GenAuth';

  @override
  String get deleteAccount => 'Hapus Akun';

  @override
  String get searchHint => 'Cari Akun...';

  @override
  String get about => 'Tentang';

  @override
  String get language => 'Bahasa';

  @override
  String get lockapp => 'Kunci App';

  @override
  String get authenticator => 'Autentikator';

  @override
  String get unlock => 'Buka Kunci';

  @override
  String get authFailed => 'Autentikasi gagal. Silakan coba lagi.';

  @override
  String get deviceAuthUnsupported => 'Perangkat ini tidak mendukung autentikasi perangkat.';

  @override
  String get english => 'Inggris';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get aboutDescription => 'Aplikasi autentikator TOTP/2FA aman yang didukung genotp-go.';

  @override
  String get noResults => 'Tidak ada hasil';

  @override
  String get noAccountsYet => 'Belum ada akun';

  @override
  String get tapToAddFirstAccount => 'Ketuk + untuk menambahkan akun pertama';

  @override
  String get addAccount => 'Tambah akun';

  @override
  String get scanQr => 'Pindai QR';

  @override
  String get scannerUnavailableTitle => 'Pemindai tidak tersedia';

  @override
  String get scannerUnavailableMessage => 'Pemindai kamera tidak dapat dijalankan. Silakan coba lagi.';

  @override
  String get scannerRetry => 'Coba lagi';

  @override
  String get manualEntry => 'Input manual';

  @override
  String invalidQr(Object error) {
    return 'QR tidak valid: $error';
  }

  @override
  String get accountLabel => 'Akun (contoh: user@example.com)';

  @override
  String get issuerLabel => 'Penerbit (contoh: Google)';

  @override
  String get requiredField => 'Wajib diisi';

  @override
  String get secretKeyLabel => 'Kunci rahasia (Base32)';

  @override
  String get generateNewSecret => 'Buat kunci baru';

  @override
  String get algorithm => 'Algoritma';

  @override
  String get digits => 'Digit';

  @override
  String get hotpCounterBased => 'HOTP (berbasis counter)';

  @override
  String get defaultTotpTimeBased => 'Default adalah TOTP (berbasis waktu)';

  @override
  String get periodSeconds => 'Periode (detik)';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String removeAccount(Object accountName) {
    return 'Hapus $accountName?';
  }

  @override
  String get nextCode => 'Kode berikutnya';

  @override
  String get codeCopied => 'Kode disalin';

  @override
  String get skip => 'Lewati';

  @override
  String get next => 'Lanjut';

  @override
  String get getStarted => 'Mulai';

  @override
  String get onboardingTitle1 => 'Selamat datang di GenAuth';

  @override
  String get onboardingDesc1 => 'Simpan kode TOTP dan HOTP dengan aman di satu tempat.';

  @override
  String get onboardingTitle2 => 'Tambah Akun Lebih Cepat';

  @override
  String get onboardingDesc2 => 'Pindai QR code atau isi detail akun secara manual dalam hitungan detik.';

  @override
  String get onboardingTitle3 => 'Akses Terlindungi';

  @override
  String get onboardingDesc3 => 'Aplikasi dilindungi autentikasi perangkat sebelum kamu masuk.';

  @override
  String get onboardingGuideTitle1 => 'Tambah Akun dan Buat OTP';

  @override
  String get onboardingGuideDesc1 => 'Tambahkan akun lewat scan QR atau input manual. Setelah itu GenAuth otomatis membuat kode OTP di halaman utama.';

  @override
  String get onboardingGuideTitle2 => 'Cari dan Rapikan Akun';

  @override
  String get onboardingGuideDesc2 => 'Gunakan pencarian dan tag untuk menemukan akun lebih cepat, lalu atur urutannya sesuai alur kerja kamu.';

  @override
  String get onboardingGuideTitle3 => 'Lindungi dan Pulihkan Data';

  @override
  String get onboardingGuideDesc3 => 'Gunakan lock, PIN, atau Panic PIN untuk perlindungan, dan siapkan cadangan lewat Backup & Restore.';

  @override
  String get onboardingDone => 'Selesai';

  @override
  String get backupAndRestore => 'Cadangkan & Pulihkan';

  @override
  String get googleAuthSectionTitle => 'Google Authenticator';

  @override
  String get googleAuthSectionDesc => 'Impor QR ekspor multi-akun dari Google Authenticator dan buat QR ekspor kompatibel dari GenAuth.';

  @override
  String get googleAuthImportAction => 'Impor dari QR';

  @override
  String get googleAuthExportAction => 'Ekspor sebagai QR';

  @override
  String get googleAuthNoAccounts => 'Belum ada akun untuk diekspor ke Google Authenticator.';

  @override
  String get googleAuthExportTitle => 'Ekspor ke Google Authenticator';

  @override
  String get googleAuthExportHint => 'Buka Google Authenticator di perangkat lain, pilih impor akun, lalu pindai setiap QR secara berurutan.';

  @override
  String googleAuthExportIntro(int count) {
    return 'Ekspor ini berisi $count akun. Jika diperlukan, GenAuth akan membaginya menjadi beberapa QR yang bisa dibaca Google Authenticator.';
  }

  @override
  String googleAuthBatchLabel(int current, int total) {
    return 'QR $current dari $total';
  }

  @override
  String googleAuthBatchAccounts(int count) {
    return '$count akun di QR ini';
  }

  @override
  String get googleAuthTableQr => 'QR';

  @override
  String get googleAuthTableIssuer => 'Penerbit';

  @override
  String get googleAuthTableAccount => 'Akun';

  @override
  String get googleAuthTableType => 'Tipe';

  @override
  String get backupExportTitle => 'Ekspor Cadangan';

  @override
  String get backupExportDesc => 'Akun dienkripsi dengan kata sandi sebelum diekspor. Simpan file ke iCloud Drive, Google Drive, atau penyimpanan lain yang kamu gunakan.';

  @override
  String get backupPassword => 'Kata sandi cadangan';

  @override
  String get backupPasswordConfirm => 'Konfirmasi kata sandi';

  @override
  String get backupPasswordMin => 'Minimal 8 karakter';

  @override
  String get backupPasswordMismatch => 'Kata sandi tidak cocok';

  @override
  String get backupExportShare => 'Ekspor & Bagikan';

  @override
  String get backupEncrypting => 'Mengenkripsi...';

  @override
  String get backupShareSubject => 'Backup GenAuth';

  @override
  String backupSavedFile(Object fileName) {
    return 'Backup berhasil dibuat: $fileName';
  }

  @override
  String get backupNoAccounts => 'Tidak ada akun untuk diekspor.';

  @override
  String get backupRestoreTitle => 'Pulihkan Cadangan';

  @override
  String get backupRestoreDesc => 'Pilih file cadangan .genauth dan masukkan kata sandi yang digunakan saat mengekspor.';

  @override
  String get backupChooseFile => 'Pilih file cadangan';

  @override
  String get backupDecrypting => 'Mendekripsi...';

  @override
  String get backupRestore => 'Pulihkan';

  @override
  String get backupRestoreDialogTitle => 'Pulihkan cadangan';

  @override
  String backupRestoreDialogContent(int count) {
    return 'Ditemukan $count akun di cadangan.\n\nGanti: menghapus semua akun saat ini dan menggunakan cadangan.\nGabung: menambahkan akun dari cadangan yang belum ada.';
  }

  @override
  String get backupMerge => 'Gabung';

  @override
  String get backupReplace => 'Ganti';

  @override
  String backupRestoredSuccess(int count) {
    return '$count akun berhasil dipulihkan.';
  }

  @override
  String backupInvalidFile(Object error) {
    return 'File cadangan tidak valid: $error';
  }

  @override
  String get backupWrongPassword => 'Kata sandi salah atau file rusak.';

  @override
  String backupExportFailed(Object error) {
    return 'Ekspor gagal: $error';
  }

  @override
  String accountsImported(int count) {
    return '$count akun berhasil diimpor.';
  }

  @override
  String get accountsAlreadyImported => 'Semua akun dari QR ini sudah ada di GenAuth.';

  @override
  String get pinEnterTitle => 'Masukkan PIN';

  @override
  String get pinSetupTitle => 'Atur PIN';

  @override
  String get pinConfirmTitle => 'Konfirmasi PIN';

  @override
  String get pinSetupDesc => 'Atur PIN 6 digit sebagai metode buka kunci cadangan';

  @override
  String get pinConfirmDesc => 'Masukkan PIN yang sama lagi untuk konfirmasi';

  @override
  String get pinWrong => 'PIN salah. Coba lagi.';

  @override
  String get pinMismatch => 'PIN tidak cocok. Coba lagi.';

  @override
  String get pinSaved => 'PIN berhasil diatur';

  @override
  String get pinRemoved => 'PIN dihapus';

  @override
  String get usePin => 'Gunakan PIN';

  @override
  String get setPinOption => 'Atur PIN';

  @override
  String get removePinOption => 'Hapus PIN';

  @override
  String get setPanicPinOption => 'Atur Panic PIN';

  @override
  String get removePanicPinOption => 'Hapus Panic PIN';

  @override
  String get panicPinOptionSubtitle => 'PIN darurat penghancur data';

  @override
  String get panicPinRemoved => 'Panic PIN dihapus';

  @override
  String get panicPinSetupTitle => 'Atur Panic PIN';

  @override
  String get panicPinConfirmTitle => 'Konfirmasi Panic PIN';

  @override
  String get panicPinSetupDesc => 'PIN darurat ini akan menghapus seluruh data OTP saat dipakai';

  @override
  String get panicPinConfirmDesc => 'Masukkan ulang Panic PIN yang sama untuk konfirmasi';

  @override
  String get panicPinSaved => 'Panic PIN berhasil disimpan';

  @override
  String get panicCorruptedTitle => 'Kesalahan Database';

  @override
  String get panicCorruptedDesc => 'Aplikasi tidak dapat memuat data lokal karena kerusakan integritas penyimpanan.';

  @override
  String get panicCorruptedHelp => 'Silakan pulihkan dari backup yang tersedia atau instal ulang aplikasi.';

  @override
  String get quickActions => 'Aksi Cepat';

  @override
  String get close => 'Tutup';

  @override
  String get auditLogTitle => 'Log Audit';

  @override
  String get auditLogMenu => 'Aktivitas Audit';

  @override
  String get auditLogEmpty => 'Belum ada aktivitas yang tercatat.';

  @override
  String get auditLogClearAll => 'Hapus semua log';

  @override
  String get auditLogClearConfirmTitle => 'Hapus log audit?';

  @override
  String get auditLogClearConfirmDesc => 'Tindakan ini akan menghapus permanen semua catatan audit lokal.';

  @override
  String get auditLogStatus => 'Status';

  @override
  String get auditLogDetail => 'Detail';

  @override
  String get auditLogMetadata => 'Metadata';

  @override
  String get auditLogCleared => 'Log audit dihapus';

  @override
  String get privacyPolicyMenu => 'Kebijakan Privasi';

  @override
  String get privacyPolicyTitle => 'Kebijakan Privasi';

  @override
  String get privacyPolicyNotConfigured => 'URL kebijakan privasi belum dikonfigurasi. Atur di lib/utils/app_links.dart.';

  @override
  String get privacyPolicyInvalidUrl => 'URL kebijakan privasi tidak valid. Gunakan URL http/https yang benar.';

  @override
  String get privacyPolicyLoadFailed => 'Halaman kebijakan privasi gagal dimuat. Silakan coba lagi nanti.';

  @override
  String get privacyPolicyOpenExternalHint => 'Di platform ini, kebijakan privasi dibuka di tampilan browser sistem.';

  @override
  String get privacyPolicyOpenExternal => 'Buka Kebijakan Privasi';

  @override
  String get termsConditionsMenu => 'Syarat & Ketentuan';

  @override
  String get termsConditionsNotConfigured => 'URL Syarat & Ketentuan belum dikonfigurasi. Atur di lib/utils/app_links.dart.';

  @override
  String get termsConditionsInvalidUrl => 'URL Syarat & Ketentuan tidak valid. Gunakan URL http/https yang benar.';

  @override
  String get termsConditionsLoadFailed => 'Halaman Syarat & Ketentuan gagal dimuat. Silakan coba lagi nanti.';

  @override
  String get drawerSectionSecurity => 'Keamanan';

  @override
  String get drawerSectionData => 'Data dan Privasi';

  @override
  String get drawerSectionApp => 'Aplikasi';

  @override
  String get tags => 'Tag';

  @override
  String get addTag => 'Tambah';

  @override
  String get editTags => 'Edit Tag';

  @override
  String get tagHint => 'Nama tag...';

  @override
  String get done => 'Selesai';

  @override
  String get githubLinkOpenFailed => 'Tidak dapat membuka tautan GitHub.';

  @override
  String get openGithubRepository => 'Buka repositori GitHub';

  @override
  String get allRightsReserved => 'Hak cipta dilindungi.';

  @override
  String versionLabel(Object version) {
    return 'Versi $version';
  }
}
