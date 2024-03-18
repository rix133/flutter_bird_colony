import 'package:flutter_test/flutter_test.dart';
import 'package:kakrarahu/icons/my_flutter_app_icons.dart';

void main() {
  group('CustomIcons', () {
    test('birdIcon_hasExpectedValues', () {
      expect(CustomIcons.bird.codePoint, 0xe800);
      expect(CustomIcons.bird.fontFamily, 'MyFlutterApp');
      expect(CustomIcons.bird.fontPackage, null);
    });
  });
}
