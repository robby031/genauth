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
}
