@JS()
library webxr_bindings;

import 'dart:html';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS("XR")
class XR {

}

XR get navigatorXr {
  return getProperty(window.navigator, 'xr');
}