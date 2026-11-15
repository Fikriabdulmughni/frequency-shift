shader_type canvas_item;

uniform vec4 warna : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float kekuatan : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float terang = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 hasil = terang * warna.rgb * 1.6;
	COLOR = vec4(mix(tex.rgb, hasil, kekuatan), tex.a * warna.a);
}