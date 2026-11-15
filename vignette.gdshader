shader_type canvas_item;

uniform vec4 warna_vignette : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float kekuatan : hint_range(0.0, 1.0) = 0.65;
uniform float radius : hint_range(0.0, 1.0) = 0.42;
uniform float kehalusan : hint_range(0.01, 1.0) = 0.55;
uniform float denyut_kecepatan : hint_range(0.0, 5.0) = 1.2;
uniform float denyut_amplitudo : hint_range(0.0, 0.2) = 0.03;
uniform float kedip : hint_range(0.0, 1.0) = 0.0; // diisi dari script

void fragment() {
	// Koreksi rasio layar supaya vignette berbentuk lingkaran, bukan elips
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = (UV - 0.5) * vec2(res.x / res.y, 1.0);
	float jarak = length(uv);

	// Radius berdenyut pelan
	float r = radius + sin(TIME * denyut_kecepatan) * denyut_amplitudo;
	float v = smoothstep(r, r + kehalusan, jarak);

	float alpha = clamp(v * (kekuatan + kedip), 0.0, 1.0);
	COLOR = vec4(warna_vignette.rgb, alpha);
}