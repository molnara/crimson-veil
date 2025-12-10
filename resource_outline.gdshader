shader_type spatial;
render_mode unshaded, cull_front;

// Outline color and width
uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Expand vertices along their normals to create outline effect
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	// Simple solid color for the outline
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
