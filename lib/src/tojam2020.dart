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
import 'rope.dart';

gltf.Model model;
gltf.Model floorModel;
gltf.Model blockModel;

Quaternion baseAngleAdjust = Quaternion.I();
List<double> basePosAdjust = [0.0, -0.5, 0.0];

num lastTime = null;

void loadResources() {
    // Start loading some resources immediately
  gltf.loadGlb('resources/3blocks.glb').then((gltfmodel) {
    model = gltfmodel;
  });
  gltf.loadGlb('resources/ming_floor.glb').then((gltfmodel) {
    floorModel = gltfmodel;
    // Coordinate range is (0->4, 2->2.4, -4->4)
  });
  gltf.loadGlb('resources/singleblock.glb').then((gltfmodel) {
    blockModel = gltfmodel;
    // Coordinate range is (1.9->2, 2->2.1, -1.8->-1.7)
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
    uiDiv.appendHtml('<a href="#" class="startVr"><div><span>Start VR</span></div></a>');
    uiDiv.querySelector('.startVr').addEventListener('click', (event) {
//      uiDiv.appendText('clicked');
      _startInline("immersive-vr", "local");
      event.preventDefault();
    });
  });

  // Show the 'Start inline' button
  promiseToFuture<bool>(navigatorXr.isSessionSupported("inline"))
      .then((supported) {
    if (!supported) return;
    uiDiv.appendHtml(
        '<a href="#" class="startInline"><div><span>Start Inline</span></div></a>');
    uiDiv.querySelector('.startInline').addEventListener('click',
        (event) {
//      uiDiv.appendText('clicked');
      _startInline("inline", "viewer");
      event.preventDefault();
    });
  });
}

StreamSubscription keyListener;
Element _uiDiv;
shaders.SimpleTriProgram triProgram;
shaders.TexturedProgram textureProgram;
XRRigidTransform startSelectTransform;
XRInputSource startSelectInputSource;

void createExitVrButton(XRSession session) {
    _uiDiv.innerHtml = '';
    _uiDiv.appendHtml('<a href="#" class="exitVR"><div><span>Exit VR</span></div></a>');
    _uiDiv.querySelector('.exitVR').addEventListener('click', (evt) {
      session.end();
      if (keyListener != null) {
        keyListener.cancel();
        keyListener = null;
      }
      _uiDiv.innerHtml = '';
      showStartButton(_uiDiv);
      evt.preventDefault();
    });

}

void _startInline(String sessionType, String refType) {
  lastTime = null;
  promiseToFuture<XRSession>(navigatorXr.requestSession(sessionType))
      .then((session) {
    createExitVrButton(session);
    keyListener = document.onKeyDown.listen((evt) {
      //window.console.log(evt.keyCode);
      switch (evt.keyCode) {
        case 65: // A
          basePosAdjust[0] += 0.2;
          break;
        case 83: // S
          basePosAdjust[2] -= 0.2;
          break;
        case 68: // D
          basePosAdjust[0] -= 0.2;
          break;
        case 87: // W
          basePosAdjust[2] += 0.2;
          break;
        case 81: // Q
          baseAngleAdjust.mul(Quaternion.I().setFromAxisRad(0, 1, 0, -0.05));
          break;
        case 69: // E
          baseAngleAdjust.mul(Quaternion.I().setFromAxisRad(0, 1, 0, 0.05));
          break;
        default:
          return;
      }
      evt.preventDefault();
    });
    CanvasElement canvas = document.querySelector('canvas');
    webgl.RenderingContext gl =
        canvas.getContext('webgl', {'xrCompatible': true});
    triProgram = new shaders.SimpleTriProgram(gl);
    textureProgram = new shaders.TexturedProgram(gl);
    session.updateRenderState(
        new XRRenderStateInit(baseLayer: new XRWebGLLayer(session, gl)));
    promiseToFuture<XRReferenceSpace>(session.requestReferenceSpace(refType))
        .then((refSpace) {

      session.addEventListener('squeezestart', allowInterop((dynamic evt) {
        // My WMR headset doesn't seem to have squeeze events
      }));
      session.addEventListener('selectstart', allowInterop((dynamic evt) {
        XRInputSourceEvent event = evt as XRInputSourceEvent;
        if (event.inputSource.gripSpace != null) {
          startSelectTransform = 
            event.frame.getPose(event.inputSource.gripSpace, refSpace).transform;
          startSelectInputSource = event.inputSource;
        }
      }));
      session.addEventListener('select', allowInterop((dynamic evt) {
        XRInputSourceEvent event = evt as XRInputSourceEvent;
        var currentPose = event.frame.getPose(event.inputSource.gripSpace, refSpace).transform;
        basePosAdjust[0] += currentPose.position.x - startSelectTransform.position.x;
        basePosAdjust[1] += currentPose.position.y - startSelectTransform.position.y;
        basePosAdjust[2] += currentPose.position.z - startSelectTransform.position.z;
        startSelectTransform = null;
        startSelectInputSource = null;
      }));
      session.addEventListener('selectend', allowInterop((dynamic evt) {
        startSelectTransform = null;
        startSelectInputSource = null;
        XRInputSourceEvent event = evt as XRInputSourceEvent;
      }));

      session.requestAnimationFrame(allowInterop((time, frame) {
        _renderFrame(time, frame, gl, refSpace);
      }));
    });
  });
}

void _renderFrame(num time, XRFrame frame, webgl.RenderingContext gl, XRReferenceSpace baseRefSpace) {
  XRSession session = frame.session;

  if (lastTime == null)
    lastTime = time;
  num deltaTime = time - lastTime;
  lastTime = time;
  rotateRope(deltaTime);

  // I think I'm calling this incorrectly because the rotation seems to be
  // happening after the translation, but the spec says that that shouldn't happen.
  XRReferenceSpace refSpace = baseRefSpace
    .getOffsetReferenceSpace(new XRRigidTransform(new DOMPointInit(), new DOMPointInit(x: baseAngleAdjust.x, y: baseAngleAdjust.y, z: baseAngleAdjust.z, w: baseAngleAdjust.w)))
    .getOffsetReferenceSpace(new XRRigidTransform(new DOMPointInit(x: basePosAdjust[0], y: basePosAdjust[1], z: basePosAdjust[2])));

  // Handle dragging of the whole area
  if (startSelectTransform != null && startSelectInputSource != null) {
    var currentPose = frame.getPose(startSelectInputSource.gripSpace, baseRefSpace).transform;
    refSpace = refSpace.getOffsetReferenceSpace(new XRRigidTransform(new DOMPointInit(x: currentPose.position.x - startSelectTransform.position.x,
        y: currentPose.position.y - startSelectTransform.position.y,
        z: currentPose.position.z - startSelectTransform.position.z), new DOMPointInit()));
  }


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
    } as void Function(XRView));

    // Render normally
    pose.views.forEach((view) {
      var viewport = glLayer.getViewport(view);

      gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
      _drawScene(gl, view);
    } as void Function(XRView));

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
    _renderFrame(time, frame, gl, baseRefSpace);
  }));
}

shaders.GlRenderModel modelRender;
shaders.GlRenderModel floorRender;
shaders.GlRenderModel blockRender;

void _drawScene(webgl.RenderingContext gl, XRView view) {
  Mat4 transformMatrix = Mat4.I();
  // transformMatrix.translateThis(2, 0, -3);
  transformMatrix = Mat4.fromWebXrFloat32Array(view.transform.inverse.matrix).mul(transformMatrix);
  transformMatrix = Mat4.fromWebXrFloat32Array(view.projectionMatrix).mul(transformMatrix);
  // shaders.useShader(triProgram);
  // triProgram.loadUniforms(transformMatrix);
  // shaders.TrianglesArrayBuffer buf = triProgram.createRenderableBuffer();
  // triProgram.draw(buf);
  // buf.close();

  // if (model != null) {
  //   if (modelRender == null) {
  //     modelRender = new shaders.GlRenderModel(model, textureProgram);
  //     modelRender.createBuffers(gl);
  //   }
  //   modelRender.renderScene(gl, transformMatrix.mul(Mat4.I().translateThis(2, 0, -3)), 0);
  //   // TODO: Close the modelRender
  // }
  if (floorModel != null) {
    if (floorRender == null) {
      floorRender = new shaders.GlRenderModel(floorModel, textureProgram);
      floorRender.createBuffers(gl);
    }
    floorRender.renderScene(gl, transformMatrix.mul(
      Mat4.I()
      .scaleThis(2, 2, 2)
      .translateThis(-2, -2.1, 2)  // drop origin to floor and middle. Coordinate range is (0->4, 2->2.4, -4->0)
      ), 0);
    // TODO: Close the floorRender
  }

  if (blockModel != null) {
    if (blockRender == null) {
      blockRender = new shaders.GlRenderModel(blockModel, textureProgram);
      blockRender.createBuffers(gl);
    }
    drawRope(blockRender, gl, transformMatrix, -1, 1, -1);
    // TODO: Close the modelRender
  }
}

