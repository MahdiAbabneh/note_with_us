import 'package:flutter_test/flutter_test.dart';
import 'package:mahdeko/data/official.dart';

void main() {
  test('no one is official unless listed in the app', () {
    expect(isOfficial('someone'), isFalse);
    expect(isOfficial(''), isFalse);
  });
}
