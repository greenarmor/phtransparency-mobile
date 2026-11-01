import 'package:bettergov_budget/core/utils/links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only http(s) links are handed to the platform', () async {
    for (final unsafe in [
      null,
      '',
      'javascript:alert(1)',
      'file:///etc/passwd',
      'intent://scan/#Intent;scheme=zxing;end',
      'content://media/external/images/1',
      'tel:+639000000000',
    ]) {
      await expectLater(openExternal(unsafe), completes);
    }
  });
}
