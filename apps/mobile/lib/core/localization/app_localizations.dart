/// Mây Family Finance — Localization (vi-VN default)
///
/// Phase 0 scaffold: defines the localization delegate and a minimal
/// key set. All keys follow the pattern used in spec copywriting guide
/// (Section "Copywriting guide" of specs/02_UI_UX.md).

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// App-localized strings with vi-VN default.
///
/// Phase 0: minimal key set covering core app text.
/// Extended during each feature phase as screens are implemented.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  // -- Static lookup helper --
  static AppLocalizations? maybeOf(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  // -- Delegate (vi-VN + en-US) --
  static const _delegate = _AppLocalizationsDelegate();

  static const LocalizationsDelegate<AppLocalizations> delegate = _delegate;

  // -- Keys (Phase 0 coverage) --

  String get onboardingTitle => locale.languageCode == 'vi'
      ? 'Chào mừng bạn'
      : 'Welcome';

  String get signInWithGoogle => locale.languageCode == 'vi'
      ? 'Đăng nhập với Google'
      : 'Sign in with Google';

  String get signInWithApple => locale.languageCode == 'vi'
      ? 'Đăng nhập với Apple'
      : 'Sign in with Apple';

  String get createHousehold => locale.languageCode == 'vi'
      ? 'Tạo hộ gia đình mới'
      : 'Create new household';

  String get householdName => locale.languageCode == 'vi'
      ? 'Tên hộ gia đình'
      : 'Household name';

  String get currency => locale.languageCode == 'vi'
      ? 'Tiền tệ'
      : 'Currency';

  String get homeTabLabel => locale.languageCode == 'vi'
      ? 'Trang chủ'
      : 'Home';

  String get transactionsTabLabel => locale.languageCode == 'vi'
      ? 'Giao dịch'
      : 'Transactions';

  String get analyticsTabLabel => locale.languageCode == 'vi'
      ? 'Báo cáo'
      : 'Reports';

  String get wealthTabLabel => locale.languageCode == 'vi'
      ? 'Tài sản'
      : 'Wealth';

  String get settingsTabLabel => locale.languageCode == 'vi'
      ? 'Cá nhân'
      : 'Settings';

  // -- Common action labels --
  String get save => locale.languageCode == 'vi' ? 'Lưu' : 'Save';
  String get cancel => locale.languageCode == 'vi' ? 'Hủy' : 'Cancel';
  String get delete => locale.languageCode == 'vi' ? 'Xóa' : 'Delete';
  String get edit => locale.languageCode == 'vi' ? 'Sửa' : 'Edit';
  String get done => locale.languageCode == 'vi' ? 'Xong' : 'Done';
  String get add => locale.languageCode == 'vi' ? 'Thêm' : 'Add';
  String get confirm => locale.languageCode == 'vi' ? 'Xác nhận' : 'Confirm';
  String get retry => locale.languageCode == 'vi' ? 'Thử lại' : 'Retry';

  // -- State labels --
  String get loading => locale.languageCode == 'vi' ? 'Đang tải...' : 'Loading...';
  String get submitting => locale.languageCode == 'vi' ? 'Đang gửi...' : 'Submitting...';
  String get syncing => locale.languageCode == 'vi' ? 'Đang đồng bộ' : 'Syncing...';

  // -- Empty / error states --
  String get emptyStateTitle => locale.languageCode == 'vi'
      ? 'Chưa có dữ liệu'
      : 'No data yet';

  String get errorStateTitle => locale.languageCode == 'vi'
      ? 'Lỗi'
      : 'Error';

  // -- Money formatting (locale-aware) --
  String formatMoney(int minor, String currency) {
    final negative = minor < 0;
    final absMinor = minor.abs();
    final str = absMinor.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${negative ? '-$str' : str} $currency';
  }

  // -- Date formatting (locale-aware) --
  String formatDate(DateTime date) {
    if (locale.languageCode == 'vi') {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return intl.DateFormat('MM/dd/yyyy').format(date);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'vi' || locale.languageCode == 'en';

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
