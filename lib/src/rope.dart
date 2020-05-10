import 'dart:async';
import 'dart:html';
import 'package:tojam2020/webxr_bindings.dart';
import 'package:js/js.dart';
import 'dart:web_gl' as webgl;
import 'dart:web_gl' show WebGL;
import 'package:tojam2020/src/gl_shaders.dart' as shaders;
import 'package:tojam2020/gamegeom.dart';
import 'package:tojam2020/src/gltf_loader.dart' as gltf;
import 'dart:math' as Math;

class _LineSegment {
  num x1, y1, x2, y2;
}

void drawRope(shaders.GlRenderModel modelRender, webgl.RenderingContext gl,
    Mat4 transformMatrix, double x, double y, double z) {

  // Calculate the rope as a bunch of lines making a parabola
  num ropeExtent = 1;
  for (num ropeX = -ropeExtent; ropeX < ropeExtent; ropeX += 0.1) {
    num ropeY = ropeX * ropeX - ropeExtent * ropeExtent;
    modelRender.renderScene(gl, transformMatrix.mul(Mat4.I().translateThis(x + ropeX, y + ropeY, z)), 0);
  }


}