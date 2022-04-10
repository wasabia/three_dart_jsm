// Three.js r138 - NodeMaterial System


// uniforms

struct NodeUniformsStruct {

	nodeUniform3 : mat4x4<f32>;
	nodeUniform4 : mat4x4<f32>;

};
@binding( 0 ) @group( 0 )
var<uniform> NodeUniforms : NodeUniformsStruct;

// varys

struct NodeVarysStruct {

	@builtin( position ) Vertex: vec4<f32>;
	@location( 0 ) nodeVary0 : vec2<f32>;
	@location( 1 ) nodeVary1 : vec3<f32>;

};

// codes


@stage( vertex )
fn main( 
	@location( 0 ) position : vec3<f32>,
	@location( 1 ) uv : vec2<f32>
 ) -> NodeVarysStruct {

	// system
	var NodeVarys: NodeVarysStruct;

	// vars
	var MVP : vec4<f32>; 

	// flow
	// code
	NodeVarys.nodeVary0 = uv;
	NodeVarys.nodeVary1 = position;
	

	// FLOW -> MVP
	MVP = ( ( NodeUniforms.nodeUniform3 * NodeUniforms.nodeUniform4 ) * vec4<f32>( NodeVarys.nodeVary1, 1.0 ) );
	
	// FLOW RESULT
	NodeVarys.Vertex = MVP;

	return NodeVarys;

}