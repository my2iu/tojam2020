@Tags(const ['web'])

import 'package:test/test.dart';
import 'package:tojam2020/webxr_bindings.dart';

void main() {
  // Run with > pub run test --platform=chrome
  test('get navigator.xr', () {
    expect(navigatorXr, isNotNull);
  });
}