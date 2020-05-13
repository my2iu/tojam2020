import 'dart:typed_data';
import 'dart:web_gl' as webgl;
import 'dart:web_gl' show WebGL;
import 'package:tojam2020/src/gltf_loader.dart' as gltf;
import 'package:tojam2020/gamegeom.dart';

import 'dart:html';

GLGenericProgram _currentShader = null;
void useShader(GLGenericProgram program) {
  if (_currentShader == program) return;
  if (_currentShader != null) {
    _currentShader.unbindProgram();
  }
  _currentShader = program;
  if (_currentShader != null) {
    _currentShader.bindProgram();
  }
}

abstract class GLGenericProgram {
  webgl.RenderingContext gl;
  webgl.Program glProgram;

  void bindProgram();

  /**
   * Apparently, you have to disable your attributes after enabling them
   * because if you delete the arrays pointed to by attributes, it can
   * cause WebGL to fail on you.
   */
  void unbindProgram();

  static webgl.Program createShaderProgram(
      webgl.RenderingContext gl, String vertCode, String fragCode) {
    webgl.Shader vertShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vertShader, vertCode);
    gl.compileShader(vertShader);
    if (!gl.getShaderParameter(vertShader, WebGL.COMPILE_STATUS))
      throw gl.getShaderInfoLog(vertShader);

    // Create a simple fragment shader
    //
    webgl.Shader fragShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fragShader, fragCode);
    gl.compileShader(fragShader);
    if (!(gl.getShaderParameter(fragShader, WebGL.COMPILE_STATUS)))
      throw gl.getShaderInfoLog(fragShader);

    // Put the vertex shader and fragment shader together into
    // a complete program
    //
    webgl.Program shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertShader);
    gl.attachShader(shaderProgram, fragShader);
    gl.linkProgram(shaderProgram);
    if (!(gl.getProgramParameter(shaderProgram, WebGL.LINK_STATUS)))
      throw gl.getProgramInfoLog(shaderProgram);
    return shaderProgram;
  }
}

class SimpleTriProgram extends GLGenericProgram {
  webgl.UniformLocation uniTransform;
  int coordinatesVar;
  void loadUniforms(Mat4 transform) {
    Float32List matrix = new Float32List(16);
    for (int n = 0; n < 16; n++) matrix[n] = (transform.data[n]);
//    matrix.push(xScale);
//    matrix.push(0);
//    matrix.push(0);
//    matrix.push(0);
//
//    matrix.push(0);
//    matrix.push(yScale);
//    matrix.push(0);
//    matrix.push(0);
//
//    matrix.push(0);
//    matrix.push(0);
//    matrix.push(1);
//    matrix.push(0);
//
//    matrix.push(dx);
//    matrix.push(dy);
//    matrix.push(0);
//    matrix.push(1);

    gl.useProgram(glProgram);
    gl.uniformMatrix4fv(uniTransform, false, matrix);
  }

  SimpleTriProgram(webgl.RenderingContext gl) {
    this.gl = gl;
    String vertCode = """
      attribute vec3 coordinates;
//      attribute vec3 colours;

      varying lowp vec3 vColours;
      //varying lowp vec4 uColor;

      uniform mat4 transformMatrix;  

      void main(void) {
        vec4 viewPos = transformMatrix * vec4(coordinates, 1.0);
        gl_Position = viewPos;
        vColours = vec3(1.0, 0.0, 0.0);
      }""";
    String fragCode = """
      varying lowp vec3 vColours;

      void main(void) {
        gl_FragColor = vec4(vColours, 1.0);
      }
    """;
    glProgram = GLGenericProgram.createShaderProgram(gl, vertCode, fragCode);
    gl.useProgram(glProgram);

    uniTransform = gl.getUniformLocation(glProgram, "transformMatrix");
    loadUniforms(Mat4.I());
    coordinatesVar = gl.getAttribLocation(glProgram, "coordinates");
    // colorsVar = gl.getAttribLocation(glProgram, "colours");
  }

  void bindProgram() {
    // Tell WebGL which shader program to use
    //
    gl.useProgram(glProgram);

    gl.enableVertexAttribArray(coordinatesVar);
    // gl.enableVertexAttribArray(colorsVar);
  }

  void unbindProgram() {
    gl.disableVertexAttribArray(coordinatesVar);
    // gl.disableVertexAttribArray(colorsVar);
  }

  TrianglesArrayBuffer createRenderableBuffer() {
    // Copy an array of data points forming a triangle to the
    // graphics hardware
    //
    List<double> points = [-0.5, -0.5, -3.0, 0.5, -0.5, -3.0,
      0.5, 0.5, -3.0, -0.5, -0.5, -3.0,
      -0.5, 0.5, -3.0, 0.5, 0.5, -3.0
    ];

    TrianglesArrayBuffer triangles = new TrianglesArrayBuffer(gl);
    triangles.buffer = gl.createBuffer();
    triangles.numTriangles = (points.length / 2) as int;
    gl.bindBuffer(WebGL.ARRAY_BUFFER, triangles.buffer);
    gl.bufferData(
        WebGL.ARRAY_BUFFER, Float32List.fromList(points), WebGL.STATIC_DRAW);
    return triangles;
  }

  void draw(TrianglesArrayBuffer buffer) {
    gl.bindBuffer(WebGL.ARRAY_BUFFER, buffer.buffer);

    gl.vertexAttribPointer(coordinatesVar, 3, WebGL.FLOAT, false, 12, 0);
    // gl.vertexAttribPointer(colorsVar, 3, gl.FLOAT, false, 24, 12);

    // Now we can tell WebGL to draw the triangles
    //
//    gl.activeTexture(gl.TEXTURE0);
//    gl.bindTexture(gl.TEXTURE_2D, texture);
//    gl.uniform1i(gl.getUniformLocation(glProgram, "uSampler"), 0);
    gl.drawArrays(WebGL.TRIANGLES, 0, buffer.numTriangles * 3);
  }
}

class TrianglesArrayBuffer {
  webgl.RenderingContext gl;
  webgl.Buffer buffer;
  int numTriangles;

  TrianglesArrayBuffer(webgl.RenderingContext gl) {
    this.gl = gl;
  }
  void close() {
    gl.deleteBuffer(buffer);
  }
}

class TexturedProgram extends GLGenericProgram {
  webgl.UniformLocation uniTransform;
  webgl.UniformLocation uniSampler;
  webgl.UniformLocation uniNormalTransform;
  int coordinatesVar;
  int textureCoordinatesVar;
  int normalVar;

  void loadUniforms(Mat4 transform, Mat4 normalTransform) {
    Float32List matrix = new Float32List(16);
    for (int n = 0; n < 16; n++) matrix[n] = (transform.data[n]);
    gl.useProgram(glProgram);
    gl.uniformMatrix4fv(uniTransform, false, matrix);
    for (int n = 0; n < 16; n++) matrix[n] = (normalTransform.data[n]);
    gl.uniformMatrix4fv(uniNormalTransform, false, matrix);
  }

  TexturedProgram(webgl.RenderingContext gl) {
    this.gl = gl;
    String vertCode = """
      attribute vec3 coordinates;
      attribute vec2 texCoords;
      attribute vec3 normals;
//      attribute vec3 colours;

      varying lowp vec3 vColours;
      varying highp vec2 vTextureCoords;
      varying highp vec3 vNormal;
      //varying lowp vec4 uColor;

      uniform mat4 transformMatrix;  
      uniform mat4 normalTransformMatrix;

      void main(void) {
        vec4 viewPos = transformMatrix * vec4(coordinates, 1.0);
        gl_Position = viewPos;
        vColours = vec3(1.0, 0.0, 0.0);
        vTextureCoords = texCoords;
        vNormal = (normalTransformMatrix * vec4(normals, 0.0)).xyz;
      }""";
    String fragCode = """
      varying lowp vec3 vColours;
      varying highp vec2 vTextureCoords;
      varying highp vec3 vNormal;

      uniform sampler2D uSampler;

      void main(void) {
        //gl_FragColor = vec4(vColours, 1.0);
        highp vec3 normal = normalize(vNormal);
        highp vec3 reverseLightDirection = normalize(vec3(-0.2, 1.0, -1.0));
        highp float light = dot(normal, reverseLightDirection);
        highp vec3 directionalLightColor = vec3(0.4, 0.4, 0.4) * light;
        highp vec3 ambientLightColor = vec3(0.6, 0.6, 0.6);
           gl_FragColor = texture2D(uSampler, vTextureCoords);
          gl_FragColor.rgb = (directionalLightColor + ambientLightColor) * gl_FragColor.rgb;
      }
    """;
    glProgram = GLGenericProgram.createShaderProgram(gl, vertCode, fragCode);
    gl.useProgram(glProgram);

    uniTransform = gl.getUniformLocation(glProgram, "transformMatrix");
    uniSampler = gl.getUniformLocation(glProgram, "uSampler");
    uniNormalTransform = gl.getUniformLocation(glProgram, "normalTransformMatrix");
    loadUniforms(Mat4.I(), Mat4.I());
    coordinatesVar = gl.getAttribLocation(glProgram, "coordinates");
    textureCoordinatesVar = gl.getAttribLocation(glProgram, "texCoords");
    normalVar = gl.getAttribLocation(glProgram, "normals");

    // colorsVar = gl.getAttribLocation(glProgram, "colours");
  }

  void bindProgram() {
    // Tell WebGL which shader program to use
    //
    gl.useProgram(glProgram);

    gl.enableVertexAttribArray(coordinatesVar);
    gl.enableVertexAttribArray(textureCoordinatesVar);
    gl.enableVertexAttribArray(normalVar);
    // gl.enableVertexAttribArray(colorsVar);
  }

  void unbindProgram() {
    gl.disableVertexAttribArray(coordinatesVar);
    gl.disableVertexAttribArray(textureCoordinatesVar);
    gl.disableVertexAttribArray(normalVar);
    // gl.disableVertexAttribArray(colorsVar);
  }


  void drawGltfPrimitiveIndices(
        Mat4 transform, Mat4 normalTransform,
        gltf.Model model, gltf.Primitive primitive,
        webgl.Buffer arrayBuffer, webgl.Buffer elementArrayBuffer) {

    gl.bindBuffer(WebGL.ARRAY_BUFFER, arrayBuffer);
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, elementArrayBuffer);


    // Bind the position data
    var posAccess = model.root.accessors[primitive.attributes.POSITION];
    GlRenderModel.bindGltfAccessor(gl, posAccess, coordinatesVar, model);
    var texAccess = model.root.accessors[primitive.attributes.TEXCOORD_0];
    GlRenderModel.bindGltfAccessor(gl, texAccess, textureCoordinatesVar, model);
    var normalAccess = model.root.accessors[primitive.attributes.NORMAL];
    GlRenderModel.bindGltfAccessor(gl, normalAccess, normalVar, model);

    loadUniforms(transform, normalTransform);
    gl.uniform1i(uniSampler, 0);

    // Bind the indices and render out
    GlRenderModel.bindIndicesAndDrawElements(model, primitive, gl);

    // Now we can tell WebGL to draw the triangles
    //
//    gl.activeTexture(gl.TEXTURE0);
//    gl.bindTexture(gl.TEXTURE_2D, texture);
//    gl.uniform1i(gl.getUniformLocation(glProgram, "uSampler"), 0);
    // gl.drawArrays(WebGL.TRIANGLES, 0, buffer.numTriangles * 3);
  }
}


class GlRenderModel {
  gltf.Model model;
  // SimpleTriProgram shader;
  TexturedProgram shader;
  webgl.Buffer accessorBuf;
  webgl.Buffer indicesBuf;
  webgl.Texture blankTexture;
  List<webgl.Texture> imageTextures = new List();

  GlRenderModel(gltf.Model model, TexturedProgram shader) {
    this.model = model;
    this.shader = shader;
  }

  void createBuffers(webgl.RenderingContext gl) {
    // Load in the accessor data to the GPU
    webgl.Buffer buf = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, buf);
    gl.bufferData(
        WebGL.ARRAY_BUFFER, model.accessorMemory.data, WebGL.STATIC_DRAW);

    webgl.Buffer indexBuf = gl.createBuffer();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuf);
    gl.bufferData(WebGL.ELEMENT_ARRAY_BUFFER, model.accessorMemory.data,
        WebGL.STATIC_DRAW);

    accessorBuf = buf;
    indicesBuf = indexBuf;

    // Map images to textures
    blankTexture = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, blankTexture);
    gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 1, 1, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE,
      Uint8List.fromList([255, 255, 255, 255]));
    
    // Use the blank texture for everything initially
    for (int n = 0; n < model.images.length; n++) {
      var imgElFuture = model.images[n];
      imageTextures.add(blankTexture);
      int imgTextureIdx = n;
      imgElFuture.then((imgEl) {
        var texture = gl.createTexture();
        gl.bindTexture(WebGL.TEXTURE_2D, texture);
        gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, WebGL.RGBA, WebGL.UNSIGNED_BYTE, imgEl);
        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);
        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, WebGL.CLAMP_TO_EDGE);
        gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, WebGL.CLAMP_TO_EDGE);
        // gl.generateMipmap(WebGL.TEXTURE_2D);
        // gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 2, 2, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE,
        //   Uint8List.fromList([255, 0, 255, 255, 0, 0, 255, 255, 255, 255, 0, 255, 0, 0, 255, 255]));
        imageTextures[imgTextureIdx] = texture;
      });

    }
  }

  void close(webgl.RenderingContext gl) {
    if (indicesBuf != null)
      gl.deleteBuffer(indicesBuf);
    if (accessorBuf != null)
      gl.deleteBuffer(accessorBuf);
    imageTextures.forEach((tex) {
      if (tex == blankTexture || tex == null) {
        return;
      }
      gl.deleteTexture(tex);
    });
    if (blankTexture != null)
      gl.deleteTexture(blankTexture);

  }

  void renderScene(webgl.RenderingContext gl, Mat4 transform, int sceneIdx) {
    if (model.root.scenes[sceneIdx].nodes != null) {
      model.root.scenes[sceneIdx].nodes.forEach((nodeIdx) {
        renderNode(gl, transform, nodeIdx);
      } as void Function(int));
    }
  }

  void renderNode(webgl.RenderingContext gl, Mat4 transform, int nodeIdx) {
    gltf.Node node = model.root.nodes[nodeIdx];
    if (node.matrix != null) {
      transform = transform.mul(Mat4.fromList(node.matrix));
    } else {
      if (node.translation != null) {
        transform = transform.mul(Mat4.I().translateThis(node.translation[0], node.translation[1], node.translation[2]));
      } 
      if (node.rotation != null) {
        transform = transform.mul(new Quaternion(node.rotation[0], node.rotation[1], node.rotation[2], node.rotation[3]).toMat4());
      } 
      if (node.scale != null) {
        transform = transform.mul(Mat4.I().scaleThis(node.scale[0], node.scale[1], node.scale[2]));
      }
    }
    if (node.children != null) {
      node.children.forEach((childIdx) {
        renderNode(gl, transform, childIdx);
      } as void Function(int));
    }
    if (node.mesh != null) {
      renderMesh(gl, transform, node.mesh);
    }
  }

  static int webGlTypeFromGltfComponentType(int componentType) {
    switch (componentType) {
      case 5126:
        return WebGL.FLOAT;
      case 5121:
        return WebGL.UNSIGNED_BYTE;
      case 5122:
        return WebGL.SHORT;
      case 5123:
        return WebGL.UNSIGNED_SHORT;
      case 5125:
        return WebGL.UNSIGNED_INT;
      default:
        throw "Do not know which WebGL type represents this GLTF componentType";
    }
  }

  static int sizeForWebGlType(int type) {
    switch (type) {
      case WebGL.UNSIGNED_BYTE:
        return 1;
      case WebGL.FLOAT:
        return 4;
      case WebGL.SHORT:
        return 2;
      case WebGL.UNSIGNED_SHORT:
        return 2;
      case WebGL.UNSIGNED_INT:
        return 4;
      default:
        throw "Cannot find size for unknown webgl type";
    }
  }

  static int elementCountForAccessorType(String type) {
    switch (type) {
      case "SCALAR":
        return 1;
      case "VEC2":
        return 2;
      case "VEC3":
        return 3;
      case "VEC4":
        return 4;
      case "MAT2":
        return 4;
      case "MAT3":
        return 9;
      case "MAT4":
        return 16;
      default:
        throw "Unknown gltf accessor type";
    }
  }

  static int webGlModeFromGltfPrimitiveMode(int gltfMode) {
    if (gltfMode != null) {
      switch (gltfMode) {
        case 0:
          return WebGL.POINTS;
        case 1:
          return WebGL.LINES;
        case 2:
          return WebGL.LINE_LOOP;
        case 3:
          return WebGL.LINE_STRIP;
        case 4:
          return WebGL.TRIANGLES;
        case 5:
          return WebGL.TRIANGLE_STRIP;
        case 6:
          return WebGL.TRIANGLE_FAN;
        default:
          throw "Unknown gltf mode";
      }
    }
    return WebGL.TRIANGLES;
  }

  static void bindGltfAccessor(webgl.RenderingContext gl, gltf.Accessor posAccess, int attributeVar, gltf.Model model) {
    gltf.BufferView bufView = model.root.bufferViews[posAccess.bufferView];
    int size = GlRenderModel.elementCountForAccessorType(posAccess.type);
    int type = GlRenderModel.webGlTypeFromGltfComponentType(posAccess.componentType);
    gl.vertexAttribPointer(
        attributeVar,
        size,
        type,
        posAccess.normalized != null && posAccess.normalized,
        bufView.byteStride != null ? bufView.byteStride : 0,
        model.accessorMemory.offsetForAccessor(model, posAccess));
  }

  void renderMesh(webgl.RenderingContext gl, Mat4 transform, int meshIdx) {
    model.root.meshes[meshIdx].primitives.forEach((primitive) {
      if (primitive.indices != null) {
        // Load in the accessor data to the GPU

      useShader(shader);

      if (primitive.material != null) {
        gltf.Material mat = model.root.materials[primitive.material];
        if (mat.pbrMetallicRoughness != null 
            && (mat.pbrMetallicRoughness as gltf.PbrMetallicRoughness).baseColorTexture != null) {
          gltf.TextureReference ref = (mat.pbrMetallicRoughness as gltf.PbrMetallicRoughness).baseColorTexture;
          gltf.Texture tex = model.root.textures[ref.index];
          // if (model.images[tex.source].
          gl.activeTexture(WebGL.TEXTURE0);
          gl.bindTexture(WebGL.TEXTURE_2D, imageTextures[tex.source]);
        }
      }
    // webgl.Texture texture = gl.createTexture();

    // gl.activeTexture(WebGL.TEXTURE0);
    // gl.bindTexture(WebGL.TEXTURE_2D, texture);
    // gl.uniform1i(gl.getUniformLocation(glProgram, "uSampler"), 0);


        shader.drawGltfPrimitiveIndices(transform, Mat4.I(), model, primitive, accessorBuf, indicesBuf);


        // // Bind the position data
        // gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indicesBuf);
        // gl.bindBuffer(WebGL.ARRAY_BUFFER, accessorBuf);
        // bindGltfAccessor(gl, posAccess, shader.coordinatesVar, model);

        // shader.loadUniforms(transform);

        // // Bind the indices
        // bindIndicesAndDrawElements(model, primitive, gl);
        // gl.vertexAttribPointer(colorsVar, 3, gl.FLOAT, false, 24, 12);

        // Now we can tell WebGL to draw the triangles
        //
//    gl.activeTexture(gl.TEXTURE0);
//    gl.bindTexture(gl.TEXTURE_2D, texture);
//    gl.uniform1i(gl.getUniformLocation(glProgram, "uSampler"), 0);
        // gl.drawArrays(WebGL.TRIANGLES, 0, buffer.numTriangles * 3);

      } else {
        throw "Draw gltf non-indices not implemented";
      }
    } as void Function(gltf.Primitive));
  }

  static void bindIndicesAndDrawElements(gltf.Model model, gltf.Primitive primitive, webgl.RenderingContext gl) {
    var indexAccess = model.root.accessors[primitive.indices];
    var indexBufView = model.root.bufferViews[indexAccess.bufferView];
    int indexType =
        webGlTypeFromGltfComponentType(indexAccess.componentType);
    int indexSize = sizeForWebGlType(indexType);
    int mode = webGlModeFromGltfPrimitiveMode(primitive.mode);
    
    gl.drawElements(
        mode,
        (indexBufView.byteLength / indexSize) as int,
        indexType,
        model.accessorMemory.offsetForAccessor(model, indexAccess));
  }
}
