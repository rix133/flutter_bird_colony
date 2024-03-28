import 'package:flutter_bird_colony/icons/my_flutter_app_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomIcons', () {
    test('birdIcon_hasExpectedValues', () {
      expect(CustomIcons.bird.codePoint, 0xe800);
      expect(CustomIcons.bird.fontFamily, 'MyFlutterApp');
      expect(CustomIcons.bird.fontPackage, null);
    });
  });
}
