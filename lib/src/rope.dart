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

Quaternion ropeRotation = Quaternion.I();

void rotateRope(num deltaTime) {
  ropeRotation = Quaternion.I().setFromAxisRad(1, 0, 0, (3.0 / 2.8 * Math.pi) * deltaTime / 1000).mul(ropeRotation);
}

void drawRope(shaders.GlRenderModel modelRender, webgl.RenderingContext gl,
    Mat4 transformMatrix, double x, double y, double z) {


  // Calculate the rope as a bunch of lines making a parabola
  num ropeExtent = 1;
  num ropeStretchScale = 1.25;
  num ropeStep = 0.075;
  num lowest = 3000;
  for (num ropeX = -ropeExtent; ropeX < ropeExtent; ropeX += ropeStep) {
    num ropeY = ropeStretchScale * (ropeX * ropeX - ropeExtent * ropeExtent);
    var newRopePos = ropeRotation.toMat4().applyToList4([ropeX, ropeY, 0.0, 1.0]);
    // if (newRopePos[1] < 0) newRopePos[1] = 3;
    if (newRopePos[1] < lowest) lowest =newRopePos[1];
    modelRender.renderScene(gl, transformMatrix.mul(Mat4.I().translateThis(x + newRopePos[0], y + newRopePos[1], z + newRopePos[2])), 0);
  }
  window.console.log(lowest.toString() + " " + y.toString());


}