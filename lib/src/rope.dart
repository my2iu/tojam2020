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

void drawRope(shaders.GlRenderModel modelRender, webgl.RenderingContext gl,
    Mat4 transformMatrix, double x, double y, double z) {

  ropeRotation = Quaternion.I().setFromAxisRad(1, 0, 0, 0.01).mul(ropeRotation);

  // Calculate the rope as a bunch of lines making a parabola
  num ropeExtent = 1;
  for (num ropeX = -ropeExtent; ropeX < ropeExtent; ropeX += 0.1) {
    num ropeY = ropeX * ropeX - ropeExtent * ropeExtent;
    var newRopePos = ropeRotation.toMat4().applyToList4([ropeX, ropeY, 0.0, 1.0]);
    modelRender.renderScene(gl, transformMatrix.mul(
      Mat4.I().translateThis(x + newRopePos[0], y + newRopePos[1], z + newRopePos[2])
      .translateThis(-1.95, -2.05, 1.75) // Move center of block to origin. Coordinate range is (1.9->2, 2->2.1, -1.8->-1.7)

      ), 0);
  }


}