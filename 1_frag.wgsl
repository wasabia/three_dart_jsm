	// FLOW -> Color
	Color = vec4<f32>( NodeUniforms.nodeUniform0, 1.0 );
	// FLOW -> DiffuseColor
	DiffuseColor = Color;
	// FLOW -> OPACITY
	nodeVar2 = NodeUniforms.nodeUniform1;
	OPACITY = nodeVar2;
	DiffuseColor.a = DiffuseColor.a * OPACITY;
	// FLOW -> Output
	Output = vec4<f32>( vec2<f32>( DiffuseColor.xyz.xyz.x, DiffuseColor.w ).xy, 0.0, 1.0 );
	// FLOW RESULT
	return Output;
}