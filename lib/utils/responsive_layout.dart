import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ResponsiveLayout {
  static bool isDesktop(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width > 900;
    }
    return false;
  }
  
  static bool isMobile(BuildContext context) {
    return !isDesktop(context);
  }
}
