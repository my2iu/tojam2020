@JS()
library gltf_reader;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:js/js.dart';
import 'dart:typed_data';
import 'dart:math' as Math;


class Model {
  JsonRoot root;
  Uint8List binData;
  AccessorMemory accessorMemory;
  List<Future<ImageElement>> images = new List();

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

    // It would make more sense to do this per mesh and not for the whole
    // model at one time.
    model.accessorMemory = AccessorMemory._subsetBufferForAccessors(model, model.root.accessors);

    model.root.images.forEach((gltfImg) {
      if (gltfImg.bufferView == null) {
        model.images.add(null);
        return;
      }
      BufferView bufView = model.root.bufferViews[gltfImg.bufferView];
      if (bufView.buffer != 0) {
        model.images.add(null);
        return;
      }
      Buffer buf = model.root.buffers[bufView.buffer];
      if (buf.uri != null) {
        model.images.add(null);
        return;
      }
      int bufStart = (bufView.byteOffset != null ? bufView.byteOffset : 0);
      var imgData = model.binData.sublist(
        bufStart,
        bufStart + bufView.byteLength);
      Blob blob = new Blob([imgData], gltfImg.mimeType);
      ImageElement imgEl = document.createElement('img');
      model.images.add(imgEl.onLoad.first.then((evt) {
        // // Rescales to power of 2
        // CanvasElement imgCanvas = document.createElement('canvas');
        // int dimen = _smallestPowerOf2(Math.max(imgEl.width, imgEl.height));
        // imgCanvas.width = dimen;
        // imgCanvas.height = dimen;
        // CanvasRenderingContext2D ctx = imgCanvas.getContext('2d');
        // ctx.drawImage(imgEl, 0, 0);
        // ctx.drawImage(imgEl, 0, dimen - imgEl.height);
        // return imgCanvas;
        return imgEl;
      }));
      // imgEl.src = 'resources/256x1.png';
      imgEl.src = Url.createObjectUrl(blob);
    } as void Function(Image));
    // TODO: Also separate out the texture data, then we can just dump the
    // original buffer entirely

    return model;
  });
}

int _smallestPowerOf2(int size) {
  int pow2 = 1;
  while (pow2 < size)
    pow2 *= 2;
  return pow2;
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


class AccessorMemory {
  Uint8List data;
  int pointerShift;
  AccessorMemory(this.data, this.pointerShift);
  int offsetForAccessor(Model model, Accessor accessor) {
    BufferView bufView = model.root.bufferViews[accessor.bufferView];
    return (accessor.byteOffset != null ? accessor.byteOffset : 0) 
    + (bufView.byteOffset != null ? bufView.byteOffset : 0) 
    + pointerShift;
  }
  // For the given accessors, try to figure out which contiguous block of memory 
  // is used for them.
  // TODO: We can go even smarter than this and actually move memory around and check
  // for overlaps and stuff
  static AccessorMemory _subsetBufferForAccessors(Model model, List<Accessor> accessors) {
    // The accessor data and image data is all mixed together, but
    // we don't want to upload the image data to the GPU. So we'll
    // try to figure out which part of the buffer contains only
    // accessor data. This won't work if accessor data is intermixed
    // with image data or stored in different files etc.
    int accessorDataStart = -1, accessorDataEnd = -1;

    accessors.forEach((accessor) {
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
    } as void Function(Accessor));
    return AccessorMemory(model.binData.sublist(accessorDataStart, accessorDataEnd), -accessorDataStart);
  }

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

@JS()
@anonymous
class PbrMetallicRoughness {
  external List<double> get baseColorFactor;
  external TextureReference get baseColorTexture;
  external double get metallicFactor;
  external double get roughnessFactor;
  external TextureReference get metallicRoughnessTexture;
}

@JS()
@anonymous
class TextureReference {
  external int get index;
  external int get texCoord;
}