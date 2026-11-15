shader_type canvas_item;

uniform sampler2D layar : hint_screen_texture, filter_linear_mipmap;
uniform float kekuatan : hint_range(0.0, 1.0) = 0.0;

float acak(float x) { return fract(sin(x) * 43758.5453); }

void fragment() {
	float waktu = floor(TIME * 18.0);
	float baris = floor(SCREEN_UV.y * 60.0);
	float r = acak(baris * 7.13 + waktu);
	float geser = (r - 0.5) * 0.12 * step(0.82, r) * kekuatan;
	vec2 uv = SCREEN_UV + vec2(geser, 0.0);
	float pisah = 0.012 * kekuatan;
	vec3 c;
	c.r = texture(layar, uv + vec2(pisah, 0.0)).r;
	c.g = texture(layar, uv).g;
	c.b = texture(layar, uv - vec2(pisah, 0.0)).b;
	c += acak(SCREEN_UV.x * 1000.0 + SCREEN_UV.y * 500.0 + waktu) * kekuatan * 0.25;
	COLOR = vec4(c, 1.0);
}