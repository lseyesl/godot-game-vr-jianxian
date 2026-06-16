shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

uniform vec4 glow_color : source_color = vec4(0.1, 0.82, 0.95, 1.0);
uniform float pulse_speed : hint_range(0.0, 10.0) = 4.0;
uniform float pulse_amount : hint_range(0.0, 0.4) = 0.12;

void vertex() {
	float pulse = 1.0 + pulse_amount * sin(TIME * pulse_speed + VERTEX.x * 4.0 + VERTEX.z * 3.0);
	VERTEX *= pulse;
}

void fragment() {
	vec3 color = glow_color.rgb;
	float rim = 1.0 - max(0.0, dot(NORMAL, VIEW));
	rim = pow(rim, 2.5);
	ALBEDO = color;
	ALPHA = 0.82 + rim * 0.18;
	EMISSION = color * (1.5 + rim * 1.5);
}
