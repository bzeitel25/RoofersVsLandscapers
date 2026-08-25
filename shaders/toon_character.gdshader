shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

// ============================================================
// ROOFERS vs LANDSCAPERS — Core Toon/Cel Shader
// ============================================================
// Apply this as the primary material on all characters and props.
// Pair with outline.gdshader as a Next Pass for the full cel look.
//
// Team colors can be set per-instance via shader parameters:
//   - shadow_color: tinted shadows (purple for Roofers, green for Landscapers)
//   - rim_color: edge highlight color per team
//   - outline_color: (on the outline shader's Next Pass material)

// --- Textures ---
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Shadow / Cel Steps ---
uniform vec4 shadow_color : source_color = vec4(0.4, 0.4, 0.55, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.04;

// --- Rim Light (edge glow, light-facing) ---
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float rim_spread : hint_range(0.0, 1.0) = 0.5;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.8;

// --- Specular Highlight (optional cartoon sheen) ---
uniform float specular_size : hint_range(0.0, 1.0) = 0.15;
uniform float specular_softness : hint_range(0.0, 0.5) = 0.05;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.5;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = (tex * base_color).rgb;
}

void light() {
	// --- Stepped Diffuse (Cel Shading) ---
	float NdotL = dot(NORMAL, LIGHT);
	float intensity = smoothstep(
		shadow_threshold - shadow_softness,
		shadow_threshold + shadow_softness,
		NdotL * ATTENUATION
	);
	vec3 diffuse = mix(shadow_color.rgb * ALBEDO, ALBEDO, intensity) * LIGHT_COLOR;

	// --- Rim Light (anime edge glow, only on lit side) ---
	float NdotV = 1.0 - dot(NORMAL, VIEW);
	float rim = smoothstep(
		rim_threshold - 0.05,
		rim_threshold + 0.05,
		NdotV * pow(max(NdotL, 0.0), rim_spread)
	);
	vec3 rim_out = rim * rim_color.rgb * LIGHT_COLOR * rim_intensity;

	// --- Specular Step (cartoon sheen on shiny surfaces) ---
	vec3 half_dir = normalize(LIGHT + VIEW);
	float NdotH = dot(NORMAL, half_dir);
	float spec = smoothstep(
		1.0 - specular_size - specular_softness,
		1.0 - specular_size + specular_softness,
		NdotH
	) * specular_strength;
	vec3 spec_out = spec * specular_color.rgb * LIGHT_COLOR * ATTENUATION;

	DIFFUSE_LIGHT += diffuse + rim_out;
	SPECULAR_LIGHT += spec_out;
}
