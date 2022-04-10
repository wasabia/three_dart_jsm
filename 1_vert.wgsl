// Three.js r124 - NodeMaterial System

// uniforms
struct NodeUniformsStruct {
	nodeUniform2 : mat4x4<f32>;
	nodeUniform3 : mat4x4<f32>;
};
[[ binding( 0 ), group( 0 ) ]]
var<uniform> NodeUniforms : NodeUniformsStruct;
// varys
struct NodeVarysStruct {
	[[ builtin( position ) ]] Vertex: vec4<f32>;
	[[ location( 0 ) ]] nodeVary0 : vec3<f32>;
};
// codes
[[ stage( vertex ) ]]
fn main(
	[[ location( 0 ) ]] position : vec3<f32>
 ) -> NodeVarysStruct {
	// system
	var NodeVarys: NodeVarysStruct;
	// vars
	var nodeVar0 : mat4x4<f32>; var nodeVar1 : vec4<f32>; var MVP : vec4<f32>;
	// flow
	// code
	NodeVarys.nodeVary0 = position;
	// FLOW -> MVP
	nodeVar0 = ( NodeUniforms.nodeUniform2 * NodeUniforms.nodeUniform3 );
	nodeVar1 = ( nodeVar0 * vec4<f32>( NodeVarys.nodeVary0, 1.0 ) );
	MVP = nodeVar1;
	// FLOW RESULT
	NodeVarys.Vertex = MVP;
	return NodeVarys;
}