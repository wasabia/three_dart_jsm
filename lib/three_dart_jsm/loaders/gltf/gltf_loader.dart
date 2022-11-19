import 'dart:async';
import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:three_dart/three_dart.dart';
import 'index.dart';

class GLTFLoader extends Loader {
  late List<Function> pluginCallbacks;
  late dynamic dracoLoader;
  late dynamic ktx2Loader;
  late dynamic ddsLoader;
  late dynamic meshoptDecoder;

  GLTFLoader([manager]) : super(manager) {
    dracoLoader = null;
    ddsLoader = null;
    ktx2Loader = null;
    meshoptDecoder = null;

    pluginCallbacks = [];

    register((parser) {
      return GLTFMaterialsClearcoatExtension(parser);
    });

    register((parser) {
      return GLTFTextureBasisUExtension(parser);
    });

    register((parser) {
      return GLTFTextureWebPExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsSheenExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsTransmissionExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsVolumeExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsIorExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsSpecularExtension(parser);
    });

    register((parser) {
      return GLTFLightsExtension(parser);
    });

    register((parser) {
      return GLTFMeshoptCompression(parser);
    });
  }

  @override
  loadAsync(url) async {
    var completer = Completer();

    load(url, (buffer) {
      completer.complete(buffer);
    });

    return completer.future;
  }

  @override
  load(url, Function onLoad, [Function? onProgress, Function? onError]) {
    var scope = this;

    var resourcePath;

    if (this.resourcePath != '') {
      resourcePath = this.resourcePath;
    } else if (path != '') {
      resourcePath = path;
    } else {
      resourcePath = LoaderUtils.extractUrlBase(url);
    }

    // Tells the LoadingManager to track an extra item, which resolves after
    // the model is fully loaded. This means the count of items loaded will
    // be incorrect, but ensures manager.onLoad() does not fire early.
    manager.itemStart(url);

    // onError(e) {
    //   if (onError != null) {
    //     onError(e);
    //   } else {
    //     print(e);
    //   }

    //   scope.manager.itemError(url);
    //   scope.manager.itemEnd(url);
    // }

    var loader = FileLoader(manager);

    loader.setPath(path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);

    loader.load(url, (data) {
      // try {

      scope.parse(data, resourcePath, (gltf) {
        onLoad(gltf);

        scope.manager.itemEnd(url);
      }, onError);

      // } catch ( e ) {

      //   _onError( e );

      // }
    }, onProgress, onError);
  }

  setDRACOLoader(dracoLoader) {
    this.dracoLoader = dracoLoader;
    return this;
  }

  setDDSLoader(ddsLoader) {
    this.ddsLoader = ddsLoader;
    return this;
  }

  setKTX2Loader(ktx2Loader) {
    this.ktx2Loader = ktx2Loader;
    return this;
  }

  setMeshoptDecoder(meshoptDecoder) {
    this.meshoptDecoder = meshoptDecoder;
    return this;
  }

  register(Function callback) {
    if (!pluginCallbacks.contains(callback)) {
      pluginCallbacks.add(callback);
    }

    return this;
  }

  unregister(callback) {
    if (pluginCallbacks.contains(callback)) {
      splice(pluginCallbacks, pluginCallbacks.indexOf(callback), 1);
    }

    return this;
  }

  @override
  parse(json, [String? path, Function? onLoad, Function? onError]) {
    var content;
    var extensions = {};
    var plugins = {};

    if (json is String) {
      content = json;
    } else {
      var magic = LoaderUtils.decodeText(Uint8List.view(json.buffer, 0, 4));

      if (magic == binaryExtensionHeaderMagic) {
        // try {

        extensions[gltfExtensions["KHR_BINARY_GLTF"]] = GLTFBinaryExtension(json.buffer);

        // } catch ( error ) {

        //   if ( onError != null ) onError( error );
        //   return;

        // }

        content = extensions[gltfExtensions["KHR_BINARY_GLTF"]].content;
      } else {
        content = LoaderUtils.decodeText(json);
      }
    }

    Map<String, dynamic> decoded = convert.jsonDecode(content);

    if (decoded["asset"] == null || num.parse(decoded["asset"]["version"]) < 2.0) {
      if (onError != null) onError('THREE.GLTFLoader: Unsupported asset. glTF versions >= 2.0 are supported.');
      return;
    }

    var parser = GLTFParser(decoded, {
      "path": path ?? (resourcePath ?? ''),
      "crossOrigin": crossOrigin,
      "requestHeader": requestHeader,
      "manager": manager,
      "ktx2Loader": ktx2Loader,
      "meshoptDecoder": meshoptDecoder
    });

    parser.fileLoader.setRequestHeader(requestHeader);

    for (var i = 0; i < pluginCallbacks.length; i++) {
      var plugin = pluginCallbacks[i](parser);
      plugins[plugin.name] = plugin;

      // Workaround to avoid determining as unknown extension
      // in addUnknownExtensionsToUserData().
      // Remove this workaround if we move all the existing
      // extension handlers to plugin system
      extensions[plugin.name] = true;
    }

    if (decoded["extensionsUsed"] != null) {
      for (var i = 0; i < decoded["extensionsUsed"].length; ++i) {
        var extensionName = decoded["extensionsUsed"][i];
        var extensionsRequired = decoded["extensionsRequired"] ?? [];

        if (extensionName == gltfExtensions["KHR_MATERIALS_UNLIT"]) {
          extensions[extensionName] = GLTFMaterialsUnlitExtension();
        } else if (extensionName == gltfExtensions["KHR_MATERIALS_PBR_SPECULAR_GLOSSINESS"]) {
          extensions[extensionName] = GLTFMaterialsPbrSpecularGlossinessExtension();
        } else if (extensionName == gltfExtensions["KHR_DRACO_MESH_COMPRESSION"]) {
          extensions[extensionName] = GLTFDracoMeshCompressionExtension(decoded, dracoLoader);
        } else if (extensionName == gltfExtensions["MSFT_TEXTURE_DDS"]) {
          extensions[extensionName] = GLTFTextureDDSExtension(ddsLoader);
        } else if (extensionName == gltfExtensions["KHR_TEXTURE_TRANSFORM"]) {
          extensions[extensionName] = GLTFTextureTransformExtension();
        } else if (extensionName == gltfExtensions["KHR_MESH_QUANTIZATION"]) {
          extensions[extensionName] = GLTFMeshQuantizationExtension();
        } else {
          if (extensionsRequired.indexOf(extensionName) >= 0 && plugins[extensionName] == null) {
            print('THREE.GLTFLoader: Unknown extension $extensionName.');
          }
        }

        // switch ( extensionName ) {
        //   case EXTENSIONS["KHR_MATERIALS_UNLIT"]:
        //     extensions[ extensionName ] = new GLTFMaterialsUnlitExtension();
        //     break;
        //   case EXTENSIONS.KHR_MATERIALS_PBR_SPECULAR_GLOSSINESS:
        //     extensions[ extensionName ] = new GLTFMaterialsPbrSpecularGlossinessExtension();
        //     break;
        //   case EXTENSIONS.KHR_DRACO_MESH_COMPRESSION:
        //     extensions[ extensionName ] = new GLTFDracoMeshCompressionExtension( json, this.dracoLoader );
        //     break;
        //   case EXTENSIONS.MSFT_TEXTURE_DDS:
        //     extensions[ extensionName ] = new GLTFTextureDDSExtension( this.ddsLoader );
        //     break;
        //   case EXTENSIONS.KHR_TEXTURE_TRANSFORM:
        //     extensions[ extensionName ] = new GLTFTextureTransformExtension();
        //     break;
        //   case EXTENSIONS.KHR_MESH_QUANTIZATION:
        //     extensions[ extensionName ] = new GLTFMeshQuantizationExtension();
        //     break;
        //   default:
        //     if ( extensionsRequired.indexOf( extensionName ) >= 0 && plugins[ extensionName ] == null ) {
        //       print( 'THREE.GLTFLoader: Unknown extension ${extensionName}.' );
        //     }
        // }

      }
    }

    parser.setExtensions(extensions);
    parser.setPlugins(plugins);
    parser.parse(onLoad, onError);
  }
}
