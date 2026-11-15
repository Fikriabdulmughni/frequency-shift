extends Label
## Judul dinamis untuk HP landscape.
## Digambar manual di _draw() agar aman di dalam container.
## Ukuran font mengikuti tinggi layar, dan otomatis mengecil bila lebar label tidak cukup.

signal selesai_keluar

@export_category("Teks")
@export var teks_judul: String = "FREQUENCY SHIFT"
@export var warna_utama: Color = Color8(240, 236, 220)
@export var warna_merah: Color = Color8(255, 40, 70)
@export var warna_biru: Color = Color8(60, 220, 255)
@export var warna_outline: Color = Color(0, 0, 0, 0.9)
@export var karakter_acak: String = "#%@$&01/\\<>|:=*"

@export_category("Ukuran Responsif (HP landscape)")
## Tinggi layar acuan. Pada tinggi ini, font memakai ukuran_font_dasar.
@export var tinggi_acuan: float = 1080.0
@export var ukuran_font_dasar: int = 96
@export var ukuran_font_min: int = 28
@export var ukuran_font_maks: int = 140
## Porsi lebar label yang boleh dipakai teks (0.5 - 1.0)
@export_range(0.5, 1.0) var pemakaian_lebar: float = 0.94
@export var outline_dasar: int = 5
@export var outline_min: int = 2

@export_category("Ketik Masuk")
@export var durasi_ketik: float = 1.2
@export var jumlah_kedip_masuk: int = 5
@export var kursor: bool = true

@export_category("Glitch")
@export var interval_glitch_min: float = 2.5
@export var interval_glitch_max: float = 6.0
@export var durasi_glitch_min: float = 0.1
@export var durasi_glitch_max: float = 0.35
@export var kekuatan_split: float = 2.5
@export var kekuatan_guncang: float = 5.0
@export_range(0.0, 1.0) var peluang_acak_huruf: float = 0.35
@export var scanline: bool = true
@export_range(0.0, 1.0) var kekuatan_scanline: float = 0.22

@export_category("Keluar")
@export var durasi_keluar: float = 0.8
@export var naik_saat_keluar: float = 20.0

# status animasi
var _progres: float = 0.0
var _alpha: float = 1.0
var _kedip: float = 1.0
var _offset_x: float = 0.0
var _offset_y: float = 0.0
var _split: float = 0.0
var _acak_huruf: bool = false
var _aktif: bool = false
var _sedang_keluar: bool = false
var _timer: float = 0.0
var _jeda: float = 3.0
var _sisa_glitch: float = 0.0

# status ukuran
var _fsize: int = 96
var _outline: int = 5


func _ready() -> void:
	text = teks_judul
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	autowrap_mode = TextServer.AUTOWRAP_OFF
	clip_text = false

	# Teks asli disembunyikan, digantikan gambar manual di _draw()
	add_theme_color_override("font_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))

	resized.connect(_rapikan_ukuran)
	get_viewport().size_changed.connect(_rapikan_ukuran)

	_rapikan_ukuran()
	_jeda = randf_range(interval_glitch_min, interval_glitch_max)
	animasi_masuk()


# ---------------------------------------------------------------
# Ukuran responsif
# ---------------------------------------------------------------
func _rapikan_ukuran() -> void:
	var v: Vector2 = get_viewport_rect().size
	if v.x <= 0.0 or v.y <= 0.0 or size.x <= 1.0:
		return  # layout belum siap, akan dipanggil lagi lewat resized

	# 1. Skala dari tinggi layar (landscape)
	var skala: float = v.y / tinggi_acuan
	var target: int = roundi(ukuran_font_dasar * skala)
	target = clampi(target, ukuran_font_min, ukuran_font_maks)

	# 2. Kecilkan kalau teks lebih lebar dari porsi label
	var font: Font = get_theme_font("font")
	var lebar_maks: float = size.x * pemakaian_lebar
	if font != null and text != "":
		while target > ukuran_font_min:
			var lebar: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, target).x
			if lebar <= lebar_maks:
				break
			target -= 1

	_fsize = target
	_outline = clampi(roundi(outline_dasar * skala), outline_min, outline_dasar + 4)
	add_theme_font_size_override("font_size", _fsize)
	queue_redraw()


# ---------------------------------------------------------------
# Animasi masuk, glitch, dan keluar
# ---------------------------------------------------------------
func animasi_masuk() -> void:
	_progres = 0.0
	var t := create_tween()
	t.tween_method(_set_progres, 0.0, 1.0, durasi_ketik)
	for i in jumlah_kedip_masuk:
		t.tween_callback(func(): _alpha = randf_range(0.2, 1.0))
		t.tween_interval(0.05)
	t.tween_callback(func(): _alpha = 1.0)
	t.tween_callback(func(): _aktif = true)


func _set_progres(v: float) -> void:
	_progres = v
	queue_redraw()


func _process(delta: float) -> void:
	if not _aktif or _sedang_keluar:
		return

	_timer += delta
	if _timer >= _jeda and _sisa_glitch <= 0.0:
		_timer = 0.0
		_jeda = randf_range(interval_glitch_min, interval_glitch_max)
		_sisa_glitch = randf_range(durasi_glitch_min, durasi_glitch_max)

	if _sisa_glitch > 0.0:
		_sisa_glitch -= delta
		_offset_x = randf_range(-kekuatan_guncang, kekuatan_guncang)
		_split = kekuatan_split * randf_range(0.5, 1.6)
		_acak_huruf = randf() < peluang_acak_huruf
		_kedip = randf_range(0.55, 1.0)
		if _sisa_glitch <= 0.0:
			_reset_glitch()

	queue_redraw()


func _reset_glitch() -> void:
	_sisa_glitch = 0.0
	_offset_x = 0.0
	_split = 0.0
	_acak_huruf = false
	_kedip = 1.0


func animasi_keluar() -> void:
	if _sedang_keluar:
		return
	_sedang_keluar = true
	_reset_glitch()

	var t := create_tween()
	for i in 3:
		t.tween_callback(func(): _alpha = 0.1)
		t.tween_interval(0.05)
		t.tween_callback(func(): _alpha = 1.0)
		t.tween_interval(0.05)
	t.tween_method(_set_keluar, 0.0, 1.0, durasi_keluar)
	t.tween_callback(func():
		visible = false
		selesai_keluar.emit()
	)


func _set_keluar(v: float) -> void:
	_progres = 1.0 - v
	_alpha = 1.0 - v
	_offset_y = -naik_saat_keluar * v
	queue_redraw()


# ---------------------------------------------------------------
# Gambar
# ---------------------------------------------------------------
func _acak_char() -> String:
	return karakter_acak.substr(randi() % karakter_acak.length(), 1)


func _warna(c: Color) -> Color:
	return Color(c.r, c.g, c.b, c.a * _alpha * _kedip)


func _teks_tampil() -> String:
	var penuh: String = text
	var n: int = int(floor(penuh.length() * _progres))
	var s: String = penuh.substr(0, n)

	# Saat mengetik, satu huruf berikutnya berkedip acak
	if _progres < 1.0 and n < penuh.length():
		s += _acak_char() if randf() < 0.5 else penuh.substr(n, 1)

	# Saat glitch, sebagian huruf diacak
	if _acak_huruf:
		var hasil: String = ""
		for i in s.length():
			var ch: String = s.substr(i, 1)
			if ch != " " and randf() < 0.3:
				ch = _acak_char()
			hasil += ch
		s = hasil

	# Kursor berkedip selama mengetik
	if kursor and _progres < 1.0 and fmod(Time.get_ticks_msec() / 120.0, 2.0) < 1.0:
		s += "_"
	return s


func _draw() -> void:
	var font: Font = get_theme_font("font")
	if font == null or _alpha <= 0.0 or text == "":
		return

	var fsize: int = _fsize
	var lebar: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var asc: float = font.get_ascent(fsize)
	var desc: float = font.get_descent(fsize)

	var x0: float = (size.x - lebar) * 0.5 + _offset_x
	var y0: float = (size.y - (asc + desc)) * 0.5 + asc + _offset_y
	var tampil: String = _teks_tampil()

	# Outline hitam agar mudah dibaca di atas background ramai
	draw_string_outline(font, Vector2(x0, y0), tampil, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, _outline, _warna(warna_outline))

	# RGB split saat glitch
	if _split > 0.01:
		draw_string(font, Vector2(x0 - _split, y0), tampil, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, _warna(warna_merah))
		draw_string(font, Vector2(x0 + _split, y0), tampil, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, _warna(warna_biru))

	# Teks utama
	draw_string(font, Vector2(x0, y0), tampil, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, _warna(warna_utama))

	# Scanline
	if scanline:
		var y: float = 0.0
		var warna_garis := Color(0, 0, 0, kekuatan_scanline * _alpha)
		while y < size.y:
			draw_rect(Rect2(0, y, size.x, 1.0), warna_garis)
			y += 3.0
