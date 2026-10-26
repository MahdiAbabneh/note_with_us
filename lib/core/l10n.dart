import 'l10n_ar.dart';

/// Minimal translation layer: English strings are the keys and Arabic
/// lives in [arabicStrings].
abstract final class L10n {
  /// Whether the UI is currently Arabic.
  static bool arabic = false;
}

/// Translates an English UI string into the active language.
extension Tr on String {
  String get tr => L10n.arabic ? (arabicStrings[this] ?? this) : this;
}
