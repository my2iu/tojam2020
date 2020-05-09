@JS()
library gltf_reader;

import 'dart:convert';
import 'dart:html';
import 'package:js/js.dart';
import 'dart:web_gl' as webgl;
import 'dart:web_gl' show WebGL;
import 'dart:typed_data';

import 'package:tojam2020/src/gl_shaders.dart';

class GlRenderModel {
  Model model;
  SimpleTriProgram shader;

  GlRenderModel(Model model, SimpleTriProgram shader) {
    this.model = model;
    this.shader = shader;
  }

  void renderScene(webgl.RenderingContext gl, int sceneIdx) {
    if (model.root.scenes[sceneIdx].nodes != null) {
      model.root.scenes[sceneIdx].nodes.forEach((nodeIdx) {
        renderNode(gl, nodeIdx);
      });
    }
  }
  void renderNode(webgl.RenderingContext gl, int nodeIdx) {
    Node node = model.root.nodes[nodeIdx];
    if (node.children != null) {
      node.children.forEach((childIdx) {
        renderNode(gl, childIdx);
      });
    }
    if (node.mesh != null) {
      renderMesh(gl, node.mesh);
    }
  }

  void renderMesh(webgl.RenderingContext gl, int meshIdx) {
    model.root.meshes[meshIdx].primitives.forEach((primitive) {
      var posAccess = model.root.accessors[primitive.attributes.POSITION];
      if (primitive.indices != null) {
        // Load in the accessor data to the GPU
        webgl.Buffer buf = gl.createBuffer();
        gl.bindBuffer(WebGL.ARRAY_BUFFER, buf);
        gl.bufferData(WebGL.ARRAY_BUFFER, model.accessorData, WebGL.STATIC_DRAW);
        webgl.Buffer indexBuf = gl.createBuffer();
        gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuf);
        gl.bufferData(WebGL.ELEMENT_ARRAY_BUFFER, model.accessorData, WebGL.STATIC_DRAW);
        gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuf);

        // Bind the position data
        gl.bindBuffer(WebGL.ARRAY_BUFFER, buf);
        BufferView bufView = model.root.bufferViews[posAccess.bufferView];
        int size;
        if (posAccess.type == "VEC3")
          size = 3;
        int type;
        if (posAccess.componentType == 5126)
          type = WebGL.FLOAT;
        gl.vertexAttribPointer(shader.coordinatesVar, size, type, posAccess.normalized != null && posAccess.normalized, 
          bufView.byteStride != null ? bufView.byteStride : 0, (posAccess.byteOffset != null ? posAccess.byteOffset : 0) + (bufView.byteOffset != null ? bufView.byteOffset : 0) + model.accessorDataOffset);

        // Bind the indices
        var indexAccess = model.root.accessors[primitive.indices];
        var indexBufView = model.root.bufferViews[indexAccess.bufferView];
        int indexType;
        int indexSize;
        if (indexAccess.componentType == 5121) {
          indexType = WebGL.UNSIGNED_BYTE;
          indexSize = 1;
        } else if (indexAccess.componentType == 5123) {
          indexType = WebGL.UNSIGNED_SHORT;
          indexSize = 2;
        } else if (indexAccess.componentType == 5125) {
          indexType = WebGL.UNSIGNED_INT;
          indexSize = 4;
        }
        int mode = WebGL.TRIANGLES;
        if (primitive.mode != null) {
          if (primitive.mode == 0)
            mode = WebGL.POINTS;
          else if (primitive.mode == 1)
            mode = WebGL.LINES;
          else if (primitive.mode == 2)
            mode = WebGL.LINE_LOOP;
          else if (primitive.mode == 3)
            mode = WebGL.LINE_STRIP;
          else if (primitive.mode == 4)
            mode = WebGL.TRIANGLES;
          else if (primitive.mode == 5)
            mode = WebGL.TRIANGLE_STRIP;
          else if (primitive.mode == 6)
            mode = WebGL.TRIANGLE_FAN;
        }

        gl.drawElements(mode, (indexBufView.byteLength / indexSize) as int, indexType, 
          (indexAccess.byteOffset != null ? indexAccess.byteOffset : 0) + (indexBufView.byteOffset != null ? indexBufView.byteOffset : 0) + model.accessorDataOffset);
    // gl.vertexAttribPointer(colorsVar, 3, gl.FLOAT, false, 24, 12);

    // Now we can tell WebGL to draw the triangles
    //
//    gl.activeTexture(gl.TEXTURE0);
//    gl.bindTexture(gl.TEXTURE_2D, texture);
//    gl.uniform1i(gl.getUniformLocation(glProgram, "uSampler"), 0);
    // gl.drawArrays(WebGL.TRIANGLES, 0, buffer.numTriangles * 3);


        // Unload the accessor data
        gl.deleteBuffer(indexBuf);
        gl.deleteBuffer(buf);
      } else {

      }
    });
  }

}

class Model {
  JsonRoot root;
  Uint8List binData;
  Uint8List accessorData;
  int accessorDataOffset;
}

Future<Model> loadGlb(String file) {
  // I can't figure out how window.fetch() is supposed to work in 
  // Dart, so I'll just XMLHttpRequest it.
  return HttpRequest.request(file, responseType: 'arraybuffer').then((request) {
    ByteBuffer response = request.response;
    ByteData view = ByteData.view(response);
    int offset = 0;
    int magic = view.getUint32(offset, Endian.little);
    offset += 4;
    if (magic != 0x46546c67) {
      throw 'glTF file missing magic header';
    }
    int version = view.getUint32(offset, Endian.little);
    offset += 4;
    if (version != 2) {
      throw 'Can only handle glTF 2.0 files';
    }
    int length = view.getUint32(offset, Endian.little);
    offset += 4;

    // Read each of the chunks
    Model model = new Model();
    while (offset < length) {
      offset = _readChunk(model, view, offset);
    }

    // The accessor data and image data is all mixed together, but
    // we don't want to upload the image data to the GPU. So we'll
    // try to figure out which part of the buffer contains only
    // accessor data. This won't work if accessor data is intermixed
    // with image data or stored in different files etc.
    int accessorDataStart = -1, accessorDataEnd = -1;
    model.root.accessors.forEach((accessor) {
      if (accessor.bufferView == null) return;
      var bufView = model.root.bufferViews[accessor.bufferView];
      if (bufView.buffer != 0) return;
      if (model.root.buffers[0].uri != null) return;
      int byteOffset = bufView.byteOffset != null ? bufView.byteOffset : 0;
      if (accessorDataStart == -1 || byteOffset < accessorDataStart) {
        accessorDataStart = byteOffset;
      }
      if (accessorDataEnd == -1 || byteOffset + bufView.byteLength > accessorDataEnd) {
        accessorDataEnd = byteOffset + bufView.byteLength;
      }
      model.accessorData = model.binData.sublist(accessorDataStart, accessorDataEnd);
      model.accessorDataOffset = -accessorDataStart;
    });
    return model;
  });
}

int _readChunk(Model model, ByteData view, int offset) {
  int chunkLength = view.getUint32(offset, Endian.little);
  offset += 4;
  int chunkType = view.getUint32(offset, Endian.little);
  offset += 4;
  if (chunkType == 0x4e4f534a) {
    // JSON
    Uint8List chunkByteData = view.buffer.asUint8List(offset + view.offsetInBytes, chunkLength);
    String json = new Utf8Decoder().convert(chunkByteData);
    model.root = _Json.parse(json);
  } else if (chunkType == 0x004e4942) {
    // BIN
    Uint8List chunkByteData = view.buffer.asUint8List(offset + view.offsetInBytes, chunkLength);
    model.binData = chunkByteData;
  }
  offset += chunkLength;
  return offset;
}


// JSON parsing directly into JavaScript objects doesn't seem to be
// supported by current versions of Dart, so I'll have to provide my
// own access to that functionality.
@JS("JSON")
class _Json {
  external static dynamic parse(String data);
}

@JS()
@anonymous
class JsonRoot {
  external Asset get asset;
  external List<Accessor> get accessors;
  external List<Animation> get animations;
  external int get scene;
  external List<Buffer> get buffers;
  external List<BufferView> get bufferViews;
  external List<Camera> get cameras;
  external List<Image> get images;
  external List<Material> get materials;
  external List<Mesh> get meshes;
  external List<Node> get nodes;
  external List<Sampler> get samplers;
  external List<Scene> get scenes;
  external List<Skin> get skins;
  external List<Texture> get textures;
}

@JS()
@anonymous
class Asset {
  external String get version;

}

@JS()
@anonymous
class Accessor {
  external int get bufferView;
  external int get byteOffset;
  external int get componentType; 
  external bool get normalized;
  external int get count;
  external String get type;
  external List<num> get max;
  external List<num> get min;
  external dynamic get sparse;
  external String get name;
}

@JS()
@anonymous
class Animation {

}

@JS()
@anonymous
class Buffer {
  external String get uri;
  external int get byteLength;
  external String get name;
}

@JS()
@anonymous
class BufferView {
  external int get buffer;
  external int get byteOffset;
  external int get byteLength;
  external int get byteStride;
  external int get target;
}

@JS()
@anonymous
class Camera {

}

@JS()
@anonymous
class Image {
  external String get uri;
  external String get mimeType;
  external int get bufferView;
}

@JS()
@anonymous
class Material {
  external String get name;
  external dynamic get pbrMetallicRoughness;
  external dynamic get normalTexture;
  external dynamic get occlusionTexture;
  external dynamic get emissiveTexture;
  // other ones
}

@JS()
@anonymous
class Mesh {
  external List<Primitive> get primitives;
  external List<num> get weights;
}

@JS()
@anonymous
class Primitive {
  external PrimitiveAttributes get attributes;
  external int get indices;
  external int get material;
  external int get mode;

}

@JS()
@anonymous
class Node {
  external int get camera;
  external List<int> get children;
  external int get skin;
  external List<num> get matrix;
  external int get mesh;
  external List<num> get rotation;
  external List<num> get scale;
  external List<num> get translation;
  external List<num> get weights;
  external String get name;
}

@JS()
@anonymous
class Sampler {

}

@JS()
@anonymous
class Scene {
  external List<int> get nodes;
  external String get name;
}

@JS()
@anonymous
class Skin {

}

@JS()
@anonymous
class Texture {
  external int get sampler;
  external int get source;
  external String get name;
}

@JS()
@anonymous
class PrimitiveAttributes {
  external int get POSITION;
  external int get NORMAL;
  external int get TANGENT;
  external int get TEXCOORD_0;
  external int get TEXCOORD_1;
  external int get COLOR_0;
  external int get JOINTS_0;
  external int get WEIGHTS_0;
}