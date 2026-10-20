import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_cahier_bi/core/utils/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('montants en FCFA, sans décimales, espace pour les milliers', () {
    expect(fcfa(125000), '125 000 FCFA');
    expect(fcfa(1500.6), '1 501 FCFA');
    expect(fcfa(0), '0 FCFA');
    expect(fcfa(2500, suffix: false), '2 500');
  });

  test('saisie de montant', () {
    expect(parseMontant('12 500'), 12500);
    expect(parseMontant(''), isNull);
    expect(parseMontant('abc'), isNull);
  });

  test('numéros sénégalais', () {
    expect(nationalNumber('77 123 45 67'), '771234567');
    expect(nationalNumber('+221 77 123 45 67'), '771234567');
    expect(nationalNumber('00221771234567'), '771234567');
    expect(nationalNumber('791234567'), isNull);
    expect(nationalNumber('7712345'), isNull);
    expect(formatTelephone('771234567'), '+221 77 123 45 67');
    expect(validateTelephone('', required: false), isNull);
    expect(validateTelephone('12'), isNotNull);
  });

  test('dates de l\'API', () {
    expect(parseDate('2026-10-15'), DateTime(2026, 10, 15));
    expect(parseDate(null), isNull);
    expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
    expect(dateLongue(DateTime(2026, 10, 15)), '15 octobre 2026');
  });
}
