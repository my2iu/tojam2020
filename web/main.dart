import 'dart:html';
import 'package:tojam2020/webxr_bindings.dart';

void main() {
  document.body.innerHtml = '<div>Hello</div>';
  DivElement div = document.createElement('DIV');
  div.text = navigatorXr.toString();
  document.body.append(div);
}