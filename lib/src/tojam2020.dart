import 'dart:html';
import 'package:tojam2020/webxr_bindings.dart';
import 'package:js/js.dart';
import 'dart:web_gl' as webgl;
import 'dart:web_gl' show WebGL;
import 'package:tojam2020/src/gl_shaders.dart' as shaders;
import 'package:tojam2020/gamegeom.dart';
import 'package:tojam2020/src/gltf_loader.dart' as gltf;
import 'dart:math' as Math;

gltf.Model model;
gltf.Model floorModel;

void loadResources() {
    // Start loading some resources immediately
  gltf.loadGlb('resources/3blocks.glb').then((gltfmodel) {
    model = gltfmodel;
  });
  gltf.loadGlb('resources/ming_floor.glb').then((gltfmodel) {
    floorModel = gltfmodel;
  });

}

void showStartButton(Element uiDiv) {
  if (navigatorXr == null) {
    document.body.appendText('WebXR is not supported in this browser.');
    return;
  }
  _uiDiv = uiDiv;


  // Show the 'Start Vr' button
  promiseToFuture<bool>(navigatorXr.isSessionSupported("immersive-vr"))
      .then((supported) {
    if (!supported) return;
    uiDiv.appendHtml('<a href="#" class="startVr"><div>Start VR</div></a>');
    uiDiv.querySelector('.startVr').addEventListener('click', (event) {
      uiDiv.appendText('clicked');
      _startInline("immersive-vr", "local");
      event.preventDefault();
    });
  });

  // Show the 'Start inline' button
  promiseToFuture<bool>(navigatorXr.isSessionSupported("inline"))
      .then((supported) {
    if (!supported) return;
    uiDiv.appendHtml(
        '<a href="#" class="startInline"><div>Start Inline</div></a>');
    uiDiv.querySelector('.startInline').addEventListener('click',
        (event) {
      uiDiv.appendText('clicked');
      _startInline("inline", "viewer");
      event.preventDefault();
    });
  });
}

Element _uiDiv;
shaders.SimpleTriProgram triProgram;

void createExitVrButton(XRSession session) {
    _uiDiv.innerHtml = '';
    _uiDiv.appendHtml('<a href="#" class="exitVR"><div>Exit VR</div></a>');
    _uiDiv.querySelector('.exitVR').addEventListener('click', (evt) {
      session.end();
      _uiDiv.innerHtml = '';
      showStartButton(_uiDiv);
      evt.preventDefault();
    });

}

void _startInline(String sessionType, String refType) {
  promiseToFuture<XRSession>(navigatorXr.requestSession(sessionType))
      .then((session) {
        createExitVrButton(session);

    CanvasElement canvas = document.querySelector('canvas');
    webgl.RenderingContext gl =
        canvas.getContext('webgl', {'xrCompatible': true});
    triProgram = shaders.SimpleTriProgram(gl);
    session.updateRenderState(
        new XRRenderStateInit(baseLayer: new XRWebGLLayer(session, gl)));
    promiseToFuture<XRReferenceSpace>(session.requestReferenceSpace(refType))
        .then((refSpace) {
      session.requestAnimationFrame(allowInterop((time, frame) {
        _renderFrame(time, frame, gl, refSpace);
      }));
    });
  });
}

void _renderFrame(num time, XRFrame frame, webgl.RenderingContext gl, XRReferenceSpace refSpace) {
  XRSession session = frame.session;

  var pose = frame.getViewerPose(refSpace);
  // When VR is first started, the pose will be null until it figures out a position
  if (pose != null) {
    var glLayer = session.renderState.baseLayer;
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, glLayer.framebuffer);
    gl.clearColor(0, 0, 0, 1.0);
    gl.clearDepth(1.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    gl.enable(WebGL.DEPTH_TEST); 
    gl.depthFunc(WebGL.LEQUAL);  

    // gl.cullFace(WebGL.BACK);
    // gl.enable(WebGL.CULL_FACE);

    // Calculate viewport limits so that we can render to canvas too.
    num viewLeft = 0, viewTop = 0, viewRight = 0, viewBottom = 0;
    pose.views.forEach((view) {
      var viewport = glLayer.getViewport(view);
      viewLeft = Math.min(viewLeft, viewport.x);
      viewTop = Math.min(viewTop, viewport.y);
      viewRight = Math.max(viewRight, viewport.x + viewport.width);
      viewBottom = Math.max(viewBottom, viewport.y + viewport.height);
    });

    // Render normally
    pose.views.forEach((view) {
      var viewport = glLayer.getViewport(view);

      gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
      _drawScene(gl, view);
    });

    // Render to canvas as well
    gl.canvas.width = viewRight - viewLeft;
    gl.canvas.height = viewBottom - viewTop;
    if (glLayer.framebuffer != null) {
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
      gl.clearColor(0, 0, 0, 1.0);
      gl.clearDepth(1.0);
      gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

      pose.views.forEach((view) {
        var viewport = glLayer.getViewport(view);
        gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
        _drawScene(gl, view);
      });

    }
  }

  // Render the next frame too
  session.requestAnimationFrame(allowInterop((time, frame) {
    _renderFrame(time, frame, gl, refSpace);
  }));
}

void _drawScene(webgl.RenderingContext gl, XRView view) {
  triProgram.bindProgram();
  Mat4 transformMatrix = Mat4.I();
  // transformMatrix.translateThis(2, 0, -3);
  transformMatrix = Mat4.fromWebXrFloat32Array(view.transform.inverse.matrix).mul(transformMatrix);
  transformMatrix = Mat4.fromWebXrFloat32Array(view.projectionMatrix).mul(transformMatrix);
  triProgram.loadUniforms(transformMatrix);
  shaders.TrianglesArrayBuffer buf = triProgram.createRenderableBuffer();
  triProgram.draw(buf);
  buf.close();

  if (model != null) {
    shaders.GlRenderModel render = new shaders.GlRenderModel(model, triProgram);
    render.renderScene(gl, transformMatrix.mul(Mat4.I().translateThis(2, 0, -3)), 0);
  }
  if (floorModel != null) {
    shaders.GlRenderModel render = new shaders.GlRenderModel(floorModel, triProgram);
    render.renderScene(gl, transformMatrix.mul(Mat4.I().translateThis(-2, -2 - 1.5, 2)), 0);
  }

  triProgram.unbindProgram();
}
