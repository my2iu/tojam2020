import 'dart:html';
import 'package:tojam2020/webxr_bindings.dart';
import 'package:js/js.dart';
import 'dart:web_gl' as webgl;
import 'dart:web_gl' show WebGL;

void showStartButton() {
  if (navigatorXr == null) {
    document.body.appendText('WebXR is not supported in this browser.');
    return;
  }

  promiseToFuture<bool>(navigatorXr.isSessionSupported("immersive-vr"))
      .then((supported) {
    if (!supported) return;
    document.body
        .appendHtml('<a href="#" class="startVr"><div>Start VR</div></a>');
    document.body.querySelector('.startVr').addEventListener('click', (event) {
      document.body.appendText('clicked');
      _startInline("immersive-vr", "local");
      event.preventDefault();
    });
  });

  promiseToFuture<bool>(navigatorXr.isSessionSupported("inline"))
      .then((supported) {
    if (!supported) return;
    document.body.appendHtml(
        '<a href="#" class="startInline"><div>Start Inline</div></a>');
    document.body.querySelector('.startInline').addEventListener('click',
        (event) {
      document.body.appendText('clicked');
      _startInline("inline", "viewer");
      event.preventDefault();
    });
  });
}

void _startInline(String sessionType, String refType) {
  promiseToFuture<XRSession>(navigatorXr.requestSession(sessionType))
      .then((session) {
    CanvasElement canvas = document.querySelector('canvas');
    webgl.RenderingContext gl =
        canvas.getContext('webgl', {'xrCompatible': true});
    session.updateRenderState(
        new XRRenderStateInit(baseLayer: new XRWebGLLayer(session, gl)));
    promiseToFuture<XRReferenceSpace>(session.requestReferenceSpace(refType))
        .then((refSpace) {
      session.requestAnimationFrame(allowInterop((time, frame) {
        var pose = frame.getViewerPose(refSpace);
        if (pose == null) return;

        var glLayer = session.renderState.baseLayer;
        gl.bindFramebuffer(WebGL.FRAMEBUFFER, glLayer.framebuffer);
        gl.clearColor(0, 0, 0, 1.0);
        gl.clearDepth(1.0);
        gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

        pose.views.forEach((view) {
          var viewport = glLayer.getViewport(view);
          gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
          _drawScene(gl, view);
        });
      }));
    });
  });
}

void _drawScene(webgl.RenderingContext gl, XRView view) {

}
