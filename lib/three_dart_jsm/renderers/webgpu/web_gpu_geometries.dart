import 'package:three_dart/three_dart.dart';

import 'index.dart';

class WebGPUGeometries {
  WebGPUAttributes attributes;
  WebGPUInfo info;

  final geometries = WeakMap();

  WebGPUGeometries(this.attributes, this.info);

  update(geometry) {
    if (geometries.has(geometry) == false) {
      // var disposeCallback = onGeometryDispose.bind( this );

      // this.geometries.set( geometry, onGeometryDispose );

      info.memory["geometries"]++;

      // geometry.addEventListener( 'dispose', onGeometryDispose );

    }

    var geometryAttributes = geometry.attributes;

    for (var name in geometryAttributes.keys) {
      attributes.update(geometryAttributes[name]);
    }

    var index = geometry.index;

    if (index != null) {
      attributes.update(index, true);
    }
  }

  // onGeometryDispose( event ) {

  //   var geometry = event.target;
  //   var disposeCallback = this.geometries.get( geometry );

  //   this.geometries.delete( geometry );

  //   this.info.memory["geometries"] --;

  //   geometry.removeEventListener( 'dispose', disposeCallback );

  //   var index = geometry.index;
  //   var geometryAttributes = geometry.attributes;

  //   if ( index != null ) {

  //     this.attributes.remove( index );

  //   }

  //   for ( var name in geometryAttributes ) {

  //     this.attributes.remove( geometryAttributes[ name ] );

  //   }

  // }

}
