shader_type spatial;
render_mode unshaded; // Tidak butuh pencahayaan luar, sangat ringan

uniform vec4 magic_color : source_color = vec4(0.1, 0.8, 1.0, 1.0); // Warna Biru/Cyan
uniform float pulse_speed : hint_range(0.1, 5.0) = 2.0;

void fragment() {
    // Efek berdenyut (pulsing) lembut menggunakan fungsi waktu yang sangat aman untuk HP
    float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;
    
    // Terapkan warna dan efek pendar (emission)
    ALBEDO = magic_color.rgb * pulse;
    EMISSION = magic_color.rgb * pulse * 3.0; // Membuatnya berpendar terang jika WorldEnvironment Glow aktif
}
