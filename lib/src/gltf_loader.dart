@JS()
library gltf_reader;

import 'dart:convert';
import 'dart:html';
import 'package:js/js.dart';

import 'dart:typed_data';


class GltfModel {
  GltfJsonRoot jsonRoot;
  Uint8List binData;
}

void loadGlb(String file) {
  // I can't figure out how window.fetch() is supposed to work in 
  // Dart, so I'll just XMLHttpRequest it.
  HttpRequest.request(file, responseType: 'arraybuffer').then((request) {
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
    GltfModel model = new GltfModel();
    while (offset < length) {
      offset = _readChunk(model, view, offset);
    }
  });
}

int _readChunk(GltfModel model, ByteData view, int offset) {
  int chunkLength = view.getUint32(offset, Endian.little);
  offset += 4;
  int chunkType = view.getUint32(offset, Endian.little);
  offset += 4;
  if (chunkType == 0x4e4f534a) {
    // JSON
    Uint8List chunkByteData = view.buffer.asUint8List(offset + view.offsetInBytes, chunkLength);
    String json = new Utf8Decoder().convert(chunkByteData);
    model.jsonRoot = _Json.parse(json);
    window.console.log(model.jsonRoot);
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
class GltfJsonRoot {
  external GltfAsset get asset;
}

@JS()
@anonymous
class GltfAsset {
  external String get version;

}