shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha;

uniform vec4 shallow_color : source_color = vec4(0.12, 0.58, 0.78, 0.58);
uniform vec4 deep_color : source_color = vec4(0.02, 0.22, 0.42, 0.72);
uniform vec2 flow_direction = vec2(0.0, 1.0);
uniform float flow_phase = 0.0;
uniform float wave_scale = 5.0;
uniform float wave_strength = 0.045;

void fragment() {
	vec2 direction = normalize(flow_direction);
	vec2 moving_uv = UV + direction * flow_phase * 0.22;
	float ripple_a = sin((moving_uv.x + moving_uv.y) * wave_scale * 6.28318);
	float ripple_b = sin((moving_uv.x - moving_uv.y + flow_phase * 0.35) * wave_scale * 3.14159);
	float ripple = (ripple_a + ripple_b) * 0.5;
	vec4 color = mix(deep_color, shallow_color, 0.55 + ripple * wave_strength);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ROUGHNESS = 0.18;
	METALLIC = 0.0;
}
