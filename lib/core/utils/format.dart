import 'package:intl/intl.dart';

final _fcfa = NumberFormat.decimalPattern('fr_FR');

/// `125 000 FCFA` (sans décimales, espace comme séparateur de milliers).
String fcfa(num? montant, {bool suffix = true}) {
  final text = _fcfa
      .format((montant ?? 0).round())
      .replaceAll(RegExp(r'[  ]'), ' ');
  return suffix ? '$text FCFA' : text;
}

/// Montant saisi (« 12 500 », « 12500 ») → nombre, ou null s'il est invalide.
double? parseMontant(String? input) {
  final digits = (input ?? '')
      .replaceAll(RegExp(r'[\s  ]'), '')
      .replaceAll(',', '.');
  if (digits.isEmpty) return null;
  return double.tryParse(digits);
}

final _mobileSn = RegExp(r'^(70|71|75|76|77|78)\d{7}$');

/// Numéro national à 9 chiffres (« 771234567 »), ou null s'il n'est pas un mobile sénégalais.
String? nationalNumber(String? input) {
  var digits = (input ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00221') && digits.length == 14) {
    digits = digits.substring(5);
  }
  if (digits.startsWith('221') && digits.length == 12) {
    digits = digits.substring(3);
  }
  return _mobileSn.hasMatch(digits) ? digits : null;
}

/// `+221 77 123 45 67`
String formatTelephone(String? input) {
  final n = nationalNumber(input);
  if (n == null) return input ?? '';
  return '+221 ${n.substring(0, 2)} ${n.substring(2, 5)} ${n.substring(5, 7)} ${n.substring(7, 9)}';
}

/// Validateur de formulaire pour un mobile sénégalais.
String? validateTelephone(String? value, {bool required = true}) {
  if (value == null || value.trim().isEmpty) {
    return required ? 'Le numéro est obligatoire.' : null;
  }
  return nationalNumber(value) == null
      ? 'Numéro sénégalais invalide (ex. 77 123 45 67).'
      : null;
}

/// Date ISO `AAAA-MM-JJ` de l'API → DateTime (date locale).
DateTime? parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value.length > 10 ? value : '${value}T00:00:00');
}

/// `AAAA-MM-JJ` attendu par l'API.
String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// `12 oct. 2026`
String dateCourte(DateTime? date) =>
    date == null ? '—' : DateFormat('d MMM yyyy', 'fr_FR').format(date);

/// `12 octobre 2026`
String dateLongue(DateTime? date) =>
    date == null ? '—' : DateFormat('d MMMM yyyy', 'fr_FR').format(date);

double toDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

int? toIntOrNull(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');
