extends Control
## Layar kematian: anomali visual, anomali suara, dan kalah dari Ranger.
## Efek glitch, suara, dan alur kematian tetap sama seperti sebelumnya.
## Teks, tombol, dan latar menyesuaikan ukuran layar (PC maupun HP landscape).
## Tombol yang sudah ada di scene tetap dipakai. Kalau kosong, script membuat tombol baru.
## Animasi monster ditangani oleh kekalahan_visual.gd, jadi tidak ada gambar monster di sini.
## Teks memakai key terjemahan dan ikut bahasa yang aktif.

@export_group("Suara")
@export var suara_sentakan: AudioStream
@export_range(-80.0, 6.0) var volume_sentakan: float = 0.0
@export var suara_glitch: AudioStream
@export_range(-80.0, 6.0) var volume_glitch: float = 0.0
@export var suara_ketik: AudioStream
@export_range(-80.0, 6.0) var volume_ketik: float = 0.0

@export_group("Tampilan")
## Ukuran layar acuan. Pada ukuran ini, semua ukuran memakai angka dasar.
@export var ukuran_acuan: Vector2 = Vector2(1920, 1080)
## Batas skala agar elemen tidak terlalu kecil atau terlalu besar
@export var skala_minimum: float = 0.6
@export var skala_maksimum: float = 1.6
## Seberapa gelap latar di belakang teks (0 = tidak gelap, 1 = hitam pekat)
@export_range(0.0, 1.0) var redup_latar: float = 0.4
## Lebar teks maksimal sebagai porsi lebar layar
@export_range(0.3, 1.0, 0.05) var lebar_teks: float = 0.7
@export var warna_tombol: Color = Color(0.92, 0.92, 0.92)
@export var teks_tombol_coba: String = "KEMATIAN_TOMBOL_COBA"
@export var teks_tombol_menu: String = "KEMATIAN_TOMBOL_MENU"
@export var lebar_tombol: float = 280.0
@export var tinggi_tombol: float = 64.0
@export var ukuran_font_tombol: int = 28
@export var jarak_tombol: float = 28.0
## Jarak tepi layar ke teks (piksel pada layar acuan)
@export var margin_layar: float = 72.0
## Jarak tombol dari bawah layar (piksel pada layar acuan)
@export var margin_bawah: float = 72.0
@export var outline_teks: int = 6

@export_group("Tombol")
## Seret Button dari scene ke sini. Kalau kosong, script membuat tombol baru.
@export var tombol_coba: Button
@export var tombol_menu: Button
@export var scene_coba_lagi: String = "res://Gameplay.tscn"
@export var scene_menu: String = "res://MainMenu.tscn"
## Jeda dalam detik sebelum tombol muncul setelah efek selesai
@export var jeda_tombol: float = 0.3
## Jika aktif, tombol sudah terlihat sejak kematian dimulai
@export var tampil_tombol_sejak_awal: bool = false
## Jika aktif, tombol bisa ditekan selama efek berjalan
@export var tombol_aktif_saat_efek: bool = false
## Durasi fade hitam saat menekan tombol sebelum pindah scene
@export var durasi_fade_keluar: float = 0.6

@export_group("Kematian Visual (Jumpscare)")
## Jeda sebelum tombol muncul otomatis. Tekan layar untuk memunculkan tombol langsung
@export var jeda_tombol_visual: float = 0.3
## Kekuatan glitch yang langsung menyala dan bertahan di kematian visual
@export_range(0.0, 1.0) var kekuatan_glitch_visual: float = 0.8
## Kalau aktif, glitch terus berkedip sampai pindah scene
@export var kedip_glitch_visual: bool = true
## Rentang jeda antar kedipan (detik), x = minimum, y = maksimum
@export var interval_kedip_visual: Vector2 = Vector2(0.04, 0.3)

@export_group("Kematian Suara (Glitch Layar)")
@export_range(0.0, 1.0) var intensitas_awal_glitch_suara: float = 0.1
@export var durasi_naik_glitch_suara: float = 2.0
@export_range(0.0, 1.0) var intensitas_puncak_glitch_suara: float = 1.0
@export var durasi_turun_glitch_suara: float = 1.0
@export_range(0.0, 1.0) var intensitas_akhir_glitch_suara: float = 0.4

@export_group("Kematian Ranger (Teks)")
@export var teks_kematian_ranger: String = "KEMATIAN_RANGER"
@export var warna_teks_ranger: Color = Color(1.0, 0.25, 0.25)
## Ukuran teks pada layar 1080p. Otomatis menyesuaikan ukuran layar.
@export var ukuran_teks_ranger: int = 44
@export var durasi_ketik_teks: float = 2.5
@export_range(0.0, 1.0) var intensitas_awal_glitch_teks: float = 0.1
@export_range(0.0, 1.0) var intensitas_glitch_teks: float = 0.6

const KODE_GLITCH := """
shader_type canvas_item;
uniform sampler2D layar : hint_screen_texture, filter_nearest;
uniform float intensitas : hint_range(0.0, 1.0) = 0.0;

float acak(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float blok = floor(uv.y * 24.0);
	float geser = (acak(vec2(blok, floor(TIME * 14.0))) - 0.5) * 0.12 * intensitas;
	uv.x += geser;
	float pecah = 0.012 * intensitas;
	float r = texture(layar, uv + vec2(pecah, 0.0)).r;
	float g = texture(layar, uv).g;
	float b = texture(layar, uv - vec2(pecah, 0.0)).b;
	float garis = 1.0 - 0.15 * intensitas * step(0.5, fract(SCREEN_UV.y * 120.0));
	COLOR = vec4(vec3(r, g, b) * garis, 1.0);
}
"""

var latar_hitam: ColorRect
var latar_gambar: TextureRect
var redup: ColorRect
var teks: Label
var wadah_tombol: HBoxContainer
var glitch: ColorRect
var lapisan_fade: ColorRect
var pemutar_sentakan: AudioStreamPlayer
var pemutar_glitch: AudioStreamPlayer
var pemutar_ketik: AudioStreamPlayer
var sedang_mengetik: bool = false
var sedang_keluar: bool = false
var _tombol_visual_muncul: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_buat_node()
	_atur_tombol_awal()

	if tombol_coba:
		tombol_coba.pressed.connect(_on_coba_lagi)
	if tombol_menu:
		tombol_menu.pressed.connect(_on_menu)

	get_viewport().size_changed.connect(_rapikan_ukuran)
	_rapikan_ukuran()

	if GameState.jenis == GameState.VISUAL:
		_mulai_visual()
	elif GameState.jenis == GameState.SUARA:
		_mulai_suara()
	else:
		_mulai_ranger()


func _process(_delta: float) -> void:
	# Suara ketik diulang sampai teks selesai diketik
	if sedang_mengetik and suara_ketik != null and not pemutar_ketik.playing:
		pemutar_ketik.play()


# Kematian visual: layar ditekan langsung menampilkan tombol
func _input(event: InputEvent) -> void:
	if GameState.jenis != GameState.VISUAL or _tombol_visual_muncul:
		return
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_tampilkan_visual()


# ---------------------------------------------------------------
# Ukuran responsif
# ---------------------------------------------------------------
func _skala() -> float:
	var v: Vector2 = get_viewport_rect().size
	if v.x <= 0.0 or v.y <= 0.0:
		return 1.0
	var s: float = minf(v.x / ukuran_acuan.x, v.y / ukuran_acuan.y)
	return clampf(s, skala_minimum, skala_maksimum)


func _rapikan_ukuran() -> void:
	var v: Vector2 = get_viewport_rect().size
	var s: float = _skala()
	var pad: float = maxf(margin_layar * s, 16.0)
	var tinggi_bawah: float = margin_bawah * s + tinggi_tombol * s

	# Teks di tengah layar, di atas area tombol, dengan lebar dibatasi
	var lebar_max: float = v.x * lebar_teks
	var sisa_kiri: float = maxf((v.x - lebar_max) * 0.5, pad)
	teks.offset_left = sisa_kiri
	teks.offset_right = -sisa_kiri
	teks.offset_top = pad
	teks.offset_bottom = -(tinggi_bawah + pad * 0.5)
	teks.add_theme_font_size_override("font_size", roundi(ukuran_teks_ranger * s))
	teks.add_theme_constant_override("outline_size", roundi(outline_teks * s))

	# Tombol di tengah bawah, dalam satu baris
	wadah_tombol.offset_left = pad
	wadah_tombol.offset_right = -pad
	wadah_tombol.offset_top = -tinggi_bawah
	wadah_tombol.offset_bottom = -margin_bawah * s
	wadah_tombol.add_theme_constant_override("separation", roundi(jarak_tombol * s))

	for b: Button in [tombol_coba, tombol_menu]:
		if b:
			_gaya_tombol(b, warna_tombol)


# ---------------------------------------------------------------
# Membangun node
# ---------------------------------------------------------------
func _buat_node() -> void:
	# Latar hitam hanya terlihat jika tidak ada tangkapan layar
	latar_hitam = _kotak_penuh(Color.BLACK)
	add_child(latar_hitam)

	latar_gambar = TextureRect.new()
	latar_gambar.set_anchors_preset(Control.PRESET_FULL_RECT)
	latar_gambar.texture = GameState.gambar_terakhir
	latar_gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	latar_gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	latar_gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(latar_gambar)

	redup = _kotak_penuh(Color(0.0, 0.0, 0.0, redup_latar))
	add_child(redup)

	teks = Label.new()
	teks.set_anchors_preset(Control.PRESET_FULL_RECT)
	teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teks.add_theme_color_override("font_color", warna_teks_ranger)
	teks.add_theme_color_override("font_outline_color", Color.BLACK)
	teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teks.visible = false
	add_child(teks)

	# Wadah tombol di tengah bawah
	wadah_tombol = HBoxContainer.new()
	wadah_tombol.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wadah_tombol.alignment = BoxContainer.ALIGNMENT_CENTER
	wadah_tombol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wadah_tombol)

	tombol_coba = _siapkan_tombol(tombol_coba, teks_tombol_coba)
	tombol_menu = _siapkan_tombol(tombol_menu, teks_tombol_menu)

	# Lapisan glitch di atas gambar dan teks. Tombol dinaikkan lagi di bawah.
	glitch = _kotak_penuh(Color.WHITE)
	var shader := Shader.new()
	shader.code = KODE_GLITCH
	var bahan := ShaderMaterial.new()
	bahan.shader = shader
	glitch.material = bahan
	add_child(glitch)
	_set_glitch(0.0)

	# Lapisan fade hitam untuk transisi saat menekan tombol
	lapisan_fade = _kotak_penuh(Color(0.0, 0.0, 0.0, 0.0))
	add_child(lapisan_fade)

	wadah_tombol.move_to_front()

	pemutar_sentakan = AudioStreamPlayer.new()
	add_child(pemutar_sentakan)
	pemutar_glitch = AudioStreamPlayer.new()
	add_child(pemutar_glitch)
	pemutar_ketik = AudioStreamPlayer.new()
	add_child(pemutar_ketik)


func _kotak_penuh(warna: Color) -> ColorRect:
	var k := ColorRect.new()
	k.color = warna
	k.set_anchors_preset(Control.PRESET_FULL_RECT)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return k


# ---------------------------------------------------------------
# Tombol
# ---------------------------------------------------------------
## Memakai tombol dari scene kalau ada, kalau tidak membuat baru.
## Teks memakai key terjemahan dan ikut bahasa yang aktif.
func _siapkan_tombol(b: Button, teks_default: String) -> Button:
	var hasil: Button = b
	if hasil == null:
		hasil = Button.new()

	if hasil.get_parent() != null:
		hasil.get_parent().remove_child(hasil)
	wadah_tombol.add_child(hasil)

	Pengaturan.daftarkan_teks(hasil, teks_default)

	hasil.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hasil.pivot_offset = hasil.size * 0.5
	hasil.resized.connect(func(): hasil.pivot_offset = hasil.size * 0.5)
	hasil.mouse_entered.connect(_efek_skala.bind(hasil, 1.05))
	hasil.mouse_exited.connect(_efek_skala.bind(hasil, 1.0))
	hasil.button_down.connect(_efek_skala.bind(hasil, 0.96))
	hasil.button_up.connect(_efek_skala.bind(hasil, 1.0))

	_gaya_tombol(hasil, warna_tombol)
	return hasil


func _gaya_tombol(b: Button, warna: Color) -> void:
	var s: float = _skala()
	var r: int = roundi(10.0 * s)
	var tebal: int = roundi(3.0 * s)

	b.add_theme_stylebox_override("normal", _stil(Color(0.0, 0.0, 0.0, 0.55), warna, r, tebal))
	b.add_theme_stylebox_override("hover", _stil(Color(warna.r, warna.g, warna.b, 0.25), warna, r, tebal))
	b.add_theme_stylebox_override("pressed", _stil(Color(warna.r, warna.g, warna.b, 0.45), warna, r, tebal))
	b.add_theme_stylebox_override("focus", _stil(Color(0.0, 0.0, 0.0, 0.55), warna, r, tebal))
	b.add_theme_stylebox_override("disabled", _stil(Color(0.0, 0.0, 0.0, 0.3), Color(warna.r, warna.g, warna.b, 0.3), r, tebal))

	b.add_theme_color_override("font_color", warna)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", warna)
	b.add_theme_color_override("font_disabled_color", Color(warna.r, warna.g, warna.b, 0.35))
	b.add_theme_font_size_override("font_size", roundi(ukuran_font_tombol * s))
	b.custom_minimum_size = Vector2(lebar_tombol * s, tinggi_tombol * s)


func _stil(bg: Color, border: Color, r: int, tebal: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(tebal)
	sb.set_corner_radius_all(r)
	return sb


func _efek_skala(b: Button, skala: float) -> void:
	b.pivot_offset = b.size * 0.5
	var t := create_tween()
	t.tween_property(b, "scale", Vector2(skala, skala), 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _atur_tombol_awal() -> void:
	for b: Button in [tombol_coba, tombol_menu]:
		if b == null:
			continue
		b.visible = tampil_tombol_sejak_awal
		b.disabled = not tombol_aktif_saat_efek


func _tampilkan_tombol() -> void:
	for b: Button in [tombol_coba, tombol_menu]:
		if b == null:
			continue
		b.visible = true
		b.disabled = false


# ---------------------------------------------------------------
# Glitch dan suara
# ---------------------------------------------------------------
func _set_glitch(nilai: float) -> void:
	var bahan := glitch.material as ShaderMaterial
	bahan.set_shader_parameter("intensitas", nilai)


func _putar(pemutar: AudioStreamPlayer, suara: AudioStream, vol: float) -> void:
	if suara == null:
		return
	pemutar.stream = suara
	pemutar.volume_db = vol
	pemutar.play()


# Suara glitch hanya berbunyi selama durasi glitch
func _sfx_glitch_selama(durasi: float) -> void:
	var t := create_tween()
	t.tween_callback(_putar.bind(pemutar_glitch, suara_glitch, volume_glitch))
	t.tween_interval(durasi)
	t.tween_callback(pemutar_glitch.stop)


# ---------------------------------------------------------------
# Kematian 1: anomali visual. Glitch langsung aktif dan terus berkedip sampai pindah scene.
# Tombol muncul saat layar ditekan, atau otomatis setelah jeda.
# ---------------------------------------------------------------
func _mulai_visual() -> void:
	_set_glitch(kekuatan_glitch_visual)
	if kedip_glitch_visual:
		_kedip_visual()

	var t := create_tween()
	t.tween_interval(jeda_tombol_visual)
	t.tween_callback(_tampilkan_visual)


func _kedip_visual() -> void:
	while is_inside_tree() and not sedang_keluar:
		_set_glitch(kekuatan_glitch_visual * randf_range(0.6, 1.0))
		await get_tree().create_timer(randf_range(interval_kedip_visual.x, interval_kedip_visual.y)).timeout


func _tampilkan_visual() -> void:
	if _tombol_visual_muncul:
		return
	_tombol_visual_muncul = true
	_tampilkan_tombol()


# ---------------------------------------------------------------
# Kematian 2: anomali suara. Glitch dimulai ringan, naik, lalu turun ke intensitas akhir.
# ---------------------------------------------------------------
func _mulai_suara() -> void:
	_set_glitch(intensitas_awal_glitch_suara)
	_sfx_glitch_selama(durasi_naik_glitch_suara + durasi_turun_glitch_suara)

	var t := create_tween()
	t.tween_method(_set_glitch, intensitas_awal_glitch_suara, intensitas_puncak_glitch_suara, durasi_naik_glitch_suara)
	t.tween_method(_set_glitch, intensitas_puncak_glitch_suara, intensitas_akhir_glitch_suara, durasi_turun_glitch_suara)
	t.tween_interval(jeda_tombol)
	t.tween_callback(_tampilkan_tombol)


# ---------------------------------------------------------------
# Kematian 3: tidak menjawab event Ranger. Teks diketik dengan glitch seluruh layar.
# ---------------------------------------------------------------
func _mulai_ranger() -> void:
	teks.text = tr(teks_kematian_ranger)
	teks.visible = true
	teks.visible_characters = 0
	_set_glitch(intensitas_awal_glitch_teks)
	_sfx_glitch_selama(durasi_ketik_teks)

	sedang_mengetik = true
	_putar(pemutar_ketik, suara_ketik, volume_ketik)

	var g := create_tween()
	g.tween_method(_set_glitch, intensitas_awal_glitch_teks, intensitas_glitch_teks, durasi_ketik_teks)

	var t := create_tween()
	t.tween_property(teks, "visible_characters", teks.text.length(), durasi_ketik_teks)
	t.tween_callback(_selesai_mengetik)
	t.tween_interval(jeda_tombol)
	t.tween_callback(_tampilkan_tombol)


func _selesai_mengetik() -> void:
	sedang_mengetik = false
	pemutar_ketik.stop()


# ---------------------------------------------------------------
# Pindah scene
# ---------------------------------------------------------------
# Fade hitam dulu, baru pindah scene
func _keluar_ke(tujuan: String) -> void:
	if sedang_keluar:
		return
	sedang_keluar = true
	for b: Button in [tombol_coba, tombol_menu]:
		if b:
			b.disabled = true
	lapisan_fade.move_to_front()

	var t := create_tween()
	t.tween_property(lapisan_fade, "color:a", 1.0, durasi_fade_keluar)
	t.tween_callback(get_tree().change_scene_to_file.bind(tujuan))


func _on_coba_lagi() -> void:
	_keluar_ke(scene_coba_lagi)


func _on_menu() -> void:
	_keluar_ke(scene_menu)
