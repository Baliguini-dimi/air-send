import 'package:air_send/core/utils/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatLongDate affiche une date française non ambiguë', () {
    expect(formatLongDate(DateTime(2026, 10, 5)), '5 octobre 2026');
  });
}
