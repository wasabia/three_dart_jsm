part of jsm_helpers;

/**
 *  This helper must be added as a child of the light
 */

class RectAreaLightHelper extends Line {

  late RectAreaLight light;
  Color? color;

  RectAreaLightHelper.create(light, color) : super(light, color) {

  }

	factory RectAreaLightHelper( light, color ) {

		List<double> positions = [ 1, 1, 0, - 1, 1, 0, - 1, - 1, 0, 1, - 1, 0, 1, 1, 0 ];

		var geometry = new BufferGeometry();
		geometry.setAttribute( 'position', new Float32BufferAttribute( Float32Array.fromList(positions), 3 ) );
		geometry.computeBoundingSphere();

		var material = new LineBasicMaterial( { 'fog': false } );

		final instance =  RectAreaLightHelper.create( geometry, material );

		instance.light = light;
		instance.color = color; // optional hardwired color for the helper
		instance.type = 'RectAreaLightHelper';

		//

		List<double> positions2 = [ 1, 1, 0, - 1, 1, 0, - 1, - 1, 0, 1, 1, 0, - 1, - 1, 0, 1, - 1, 0 ];

		var geometry2 = new BufferGeometry();
		geometry2.setAttribute( 'position', new Float32BufferAttribute(  Float32Array.fromList(positions2), 3 ) );
		geometry2.computeBoundingSphere();

		instance.add( new Mesh( geometry2, new MeshBasicMaterial( { 'side': BackSide, 'fog': false } ) ) );

    return instance;
	}

	void updateMatrixWorld([bool force = false]) {

		this.scale.set( 0.5 * this.light.width!, 0.5 * this.light.height!, 1 );

		if ( this.color != null ) {

			this.material.color.set( this.color );
			this.children[ 0 ].material.color.set( this.color );

		} else {

			this.material.color.copy( this.light.color ).multiplyScalar( this.light.intensity );

			// prevent hue shift
			var c = this.material.color;
			var max = Math.max3( c.r, c.g, c.b );
			if ( max > 1 ) c.multiplyScalar( 1 / max );

			this.children[ 0 ].material.color.copy( this.material.color );

		}

		// ignore world scale on light
		this.matrixWorld.extractRotation( this.light.matrixWorld ).scale( this.scale ).copyPosition( this.light.matrixWorld );

		this.children[ 0 ].matrixWorld.copy( this.matrixWorld );

	}

	dispose() {

		this.geometry?.dispose();
		this.material.dispose();
		this.children[ 0 ].geometry?.dispose();
		this.children[ 0 ].material.dispose();

	}

}
