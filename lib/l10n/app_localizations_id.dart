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
  String get backupAndRestore => 'Cadangkan & Pulihkan';

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
