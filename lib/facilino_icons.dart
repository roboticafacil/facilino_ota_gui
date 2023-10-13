// Place fonts/facilino.ttf in your fonts/ directory and
// add the following to your pubspec.yaml
// flutter:
//   fonts:
//    - family: facilino
//      fonts:
//       - asset: fonts/facilino.ttf
import 'package:flutter/widgets.dart';

class Facilino {
  Facilino._();

  static const String _fontFamily = 'facilino';

  static const IconData facilino_letter = IconData(0xe900, fontFamily: _fontFamily);
  static const IconData arduino_letter = IconData(0xe901, fontFamily: _fontFamily);
}
