@JS()
library webxr_bindings;

import 'dart:typed_data';

import 'package:js/js_util.dart';
import 'dart:html';
import 'dart:js';
import 'package:js/js.dart';
import 'dart:web_gl' as webgl;

@JS("XR")
class XR {
  //@JS("isSessionSupported")
  external dynamic isSessionSupported(String xrSessionMode);

// Future getDevices() => promiseToFuture(JS("", "#.getDevices()", this));
  // Future<bool> isSessionSupportedDart(String mode) {
  //   return promiseToFuture(isSessionSupportedJs(mode));
  // }
  external dynamic requestSession(String xrSessionMode);
}

@JS("XRSession")
class XRSession {
  external int requestAnimationFrame(Function(num, XRFrame) callback);
  external XRRenderState get renderState;
  external void updateRenderState(XRRenderStateInit options);
  external dynamic requestReferenceSpace(String referenceSpaceType);
}

@JS("XRFrame")
class XRFrame {
  external XRSession get session;
  external XRViewerPose getViewerPose(XRReferenceSpace referenceSpace);  
}

@JS("XRRenderState")
class XRRenderState {
  external XRWebGLLayer get baseLayer;
}

@JS()
@anonymous
class XRRenderStateInit {
  external XRWebGLLayer get baseLayer;
  external num get depthFar;
  external num get depthNear;
  external num get inlineVerticalFieldOfView;

  external factory XRRenderStateInit({XRWebGLLayer baseLayer, num depthNear, num depthFar, num inlineVerticalFieldOfView});
}

@JS("XRWebGLLayer")
class XRWebGLLayer {
  external XRWebGLLayer(XRSession session, webgl.RenderingContext context);
  external webgl.Framebuffer get framebuffer;
  external num get frameBufferWidth;
  external num get frameBufferHeight;
  external XRViewport getViewport(XRView view);
}

@JS("XRSpace")
class XRSpace {

}

@JS("XRReferenceSpace")
class XRReferenceSpace {

}

@JS("XRBoundedReferenceSpace")
class XRBoundedReferenceSpace extends XRReferenceSpace {

}

@JS("XRView")
class XRView {
  external Float32List get projectionMatrix;
  external XRRigidTransform get transform;
}

@JS("XRViewport")
class XRViewport {
  external num get width;
  external num get height;
  external num get x;
  external num get y;
}

@JS("XRRigidTransform")
class XRRigidTransform {
  external DomPointReadOnly get position;
  external DomPointReadOnly get orientation;
  external Float32List get matrix;
  external XRRigidTransform get inverse;
}

@JS("XRPose")
class XRPose {

}

@JS("XRViewerPose")
class XRViewerPose {
  external List<XRView> get views;
}

@JS("XRInputSource")
class XRInputSource {

}

XR get navigatorXr {
  return getProperty(window.navigator, 'xr');
}