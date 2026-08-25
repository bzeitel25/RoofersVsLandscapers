shader_type spatial;
render_mode cull_front, unshaded;

// ============================================================
// ROOFERS vs LANDSCAPERS — Inverted Hull Outline Shader
// ============================================================
// Apply as "Next Pass" on any material using toon_character.gdshader.
// Extrudes vertices along normals and renders back-faces only,
// creating a crisp cartoon outline around the character.

uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.05) = 0.006;

void vertex() {
	// Push vertices outward along their normal to create the outline shell
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
