extends Control
## Halaman tutorial berisi gambar dan teks saja. Tidak ada gameplay di dalamnya.
## Isi halaman lewat daftar "Halaman" di Inspector.
## Root selalu menutupi seluruh layar, jadi posisi kartu tidak dipengaruhi anchor di scene.

signal dibuka
signal ditutup
signal selesai

const FILE_TUTORIAL: String = "user://tutorial.cfg"

@export var halaman: Array[HalamanTutorial] = []

@export_group("Teks Tombol")
@export var teks_lewati: String = "LEWATI"
@export var teks_sebelumnya: String = "< KEMBALI"
@export var teks_berikutnya: String = "LANJUT >"
@export var teks_mulai: String = "SELESAI"

@export_group("Tampilan")
@export var ukuran_acuan: Vector2 = Vector2(1920, 1080)
## Lebar dan tinggi maksimum kartu (persen dari layar)
@export_range(0.5, 1.0, 0.01) var porsi_kartu: float = 0.86
@export var warna_latar: Color = Color(0.03, 0.03, 0.04, 0.94)
@export var warna_kartu: Color = Color(0.09, 0.085, 0.075, 1.0)
@export var warna_aksen: Color = Color8(255, 214, 102)
@export var warna_teks: Color = Color8(235, 232, 220)
@export var warna_redup: Color = Color8(110, 110, 118)

@export_group("Perilaku")
@export var durasi_ganti_halaman: float = 0.3
## Jarak geser (piksel) untuk pindah halaman dengan swipe
@export var jarak_swipe: float = 80.0
## Tampil otomatis saat pertama kali dibuka. Setelah dilihat, tidak tampil lagi.
@export var tampil_otomatis_pertama_kali: bool = true

var _latar: ColorRect
var _kartu: PanelContainer
var _margin: MarginContainer
var _isi: VBoxContainer
var _gambar: TextureRect
var _judul: Label
var _teks: Label
var _indikator: HBoxContainer
var _btn_lewati: Button
var _btn_sebelumnya: Button
var _btn_berikutnya: Button
var _indeks: int = 0
var _terbuka: bool = false
var _tween_halaman: Tween
var _tween_buka: Tween
var _sentuh_x: float = 0.0
var _sentuh_aktif: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Abaikan transform parent (CanvasLayer), supaya ukuran root hanya diatur oleh script ini
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	# Bersihkan isi lama dari scene, semua dibangun ulang oleh script
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_bangun_ui()
	get_viewport().size_changed.connect(_rapikan_ukuran)
	_rapikan_ukuran()

	if tampil_otomatis_pertama_kali and not _sudah_dilihat():
		buka()


# ---------------------------------------------------------------
# Membangun UI
# ---------------------------------------------------------------
func _bangun_ui() -> void:
	_latar = ColorRect.new()
	_latar.color = warna_latar
	_latar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_latar)

	# CenterContainer menempatkan kartu persis di tengah layar, kiri-kanan dan atas-bawah
	var pusat := CenterContainer.new()
	pusat.set_anchors_preset(Control.PRESET_FULL_RECT)
	pusat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pusat)

	_kartu = PanelContainer.new()
	# Isi yang melebihi kartu dipotong, jadi tidak pernah keluar dari bingkai
	_kartu.clip_contents = true
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = warna_kartu
	gaya.border_color = Color(warna_aksen.r, warna_aksen.g, warna_aksen.b, 0.55)
	gaya.set_border_width_all(2)
	gaya.set_corner_radius_all(14)
	_kartu.add_theme_stylebox_override("panel", gaya)
	pusat.add_child(_kartu)

	_margin = MarginContainer.new()
	_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_kartu.add_child(_margin)

	_isi = VBoxContainer.new()
	_isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_isi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Halaman tanpa gambar tetap rata tengah secara vertikal
	_isi.alignment = BoxContainer.ALIGNMENT_CENTER
	_margin.add_child(_isi)

	# Gambar tidak punya tinggi minimum: ia hanya mengisi ruang yang tersisa
	_gambar = TextureRect.new()
	_gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gambar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gambar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_isi.add_child(_gambar)

	_judul = Label.new()
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judul.add_theme_color_override("font_color", warna_aksen)
	_isi.add_child(_judul)

	_teks = Label.new()
	_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_teks.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks.add_theme_color_override("font_color", warna_teks)
	_isi.add_child(_teks)

	_indikator = HBoxContainer.new()
	_indikator.alignment = BoxContainer.ALIGNMENT_CENTER
	_indikator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_isi.add_child(_indikator)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	_isi.add_child(footer)

	_btn_lewati = _buat_tombol(teks_lewati, false)
	footer.add_child(_btn_lewati)

	var sela := Control.new()
	sela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(sela)

	_btn_sebelumnya = _buat_tombol(teks_sebelumnya, false)
	footer.add_child(_btn_sebelumnya)

	_btn_berikutnya = _buat_tombol(teks_berikutnya, true)
	footer.add_child(_btn_berikutnya)

	_btn_lewati.pressed.connect(_lewati)
	_btn_sebelumnya.pressed.connect(_sebelumnya)
	_btn_berikutnya.pressed.connect(_berikutnya)


func _buat_tombol(teks_tombol: String, utama: bool) -> Button:
	var b := Button.new()
	b.text = teks_tombol
	var sb := StyleBoxFlat.new()
	sb.bg_color = warna_aksen if utama else Color(0.0, 0.0, 0.0, 0.35)
	sb.border_color = warna_aksen
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	var warna_font: Color = Color(0.06, 0.06, 0.06) if utama else warna_teks
	b.add_theme_color_override("font_color", warna_font)
	b.add_theme_color_override("font_hover_color", warna_font)
	b.add_theme_color_override("font_pressed_color", warna_font)
	return b


# ---------------------------------------------------------------
# Ukuran responsif (PC dan HP landscape)
# ---------------------------------------------------------------
func _skala() -> float:
	var v: Vector2 = get_viewport().get_visible_rect().size
	return clampf(minf(v.x / ukuran_acuan.x, v.y / ukuran_acuan.y), 0.6, 1.6)


func _rapikan_ukuran() -> void:
	# Root selalu menutupi seluruh layar, mulai dari pojok kiri atas
	var layar: Vector2 = get_viewport().get_visible_rect().size
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = layar

	var v: Vector2 = layar
	var s: float = _skala()

	# Kartu ukurannya tetap dan selalu di tengah. Gambar menyesuaikan sisa ruang.
	_kartu.custom_minimum_size = Vector2(
		minf(v.x * porsi_kartu, 1100.0 * s),
		minf(v.y * porsi_kartu, 720.0 * s)
	)

	var pad: int = roundi(24.0 * s)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad)
	_margin.add_theme_constant_override("margin_bottom", pad)
	_isi.add_theme_constant_override("separation", roundi(12.0 * s))

	_judul.add_theme_font_size_override("font_size", roundi(40.0 * s))
	_teks.add_theme_font_size_override("font_size", roundi(24.0 * s))
	for b: Button in [_btn_lewati, _btn_sebelumnya, _btn_berikutnya]:
		b.add_theme_font_size_override("font_size", roundi(22.0 * s))
		b.custom_minimum_size = Vector2(roundi(180.0 * s), roundi(52.0 * s))

	_segarkan_halaman()


# ---------------------------------------------------------------
# Isi halaman
# ---------------------------------------------------------------
func _segarkan_halaman() -> void:
	var s: float = _skala()
	var data: HalamanTutorial = null
	if not halaman.is_empty():
		data = halaman[_indeks]

	_gambar.texture = null
	_judul.text = ""
	_teks.text = ""
	if data:
		_gambar.texture = data.gambar
		_judul.text = tr(data.judul)
		_teks.text = tr(data.teks)
	_gambar.visible = _gambar.texture != null

	# Indikator titik di bawah teks
	for c in _indikator.get_children():
		_indikator.remove_child(c)
		c.queue_free()
	var jumlah: int = halaman.size()
	for i in jumlah:
		var titik := Label.new()
		titik.text = "●"
		titik.add_theme_font_size_override("font_size", roundi(20.0 * s))
		titik.add_theme_color_override("font_color", warna_aksen if i == _indeks else warna_redup)
		_indikator.add_child(titik)
	_indikator.visible = jumlah > 1

	# Tombol sesuai posisi halaman
	var terakhir: bool = halaman.is_empty() or _indeks >= halaman.size() - 1
	_btn_sebelumnya.disabled = _indeks <= 0
	_btn_berikutnya.text = teks_mulai if terakhir else teks_berikutnya
	_btn_lewati.visible = not terakhir


func _tampilkan(i: int) -> void:
	_indeks = clampi(i, 0, maxi(halaman.size() - 1, 0))
	_segarkan_halaman()

	# Isi halaman muncul pelan saat berganti
	if _tween_halaman and _tween_halaman.is_valid():
		_tween_halaman.kill()
	_isi.modulate.a = 0.0
	_tween_halaman = create_tween()
	_tween_halaman.tween_property(_isi, "modulate:a", 1.0, durasi_ganti_halaman)


# ---------------------------------------------------------------
# Navigasi
# ---------------------------------------------------------------
func _berikutnya() -> void:
	if halaman.is_empty() or _indeks >= halaman.size() - 1:
		_selesai_tutorial()
	else:
		_tampilkan(_indeks + 1)


func _sebelumnya() -> void:
	if _indeks > 0:
		_tampilkan(_indeks - 1)


func _lewati() -> void:
	_selesai_tutorial()


func _selesai_tutorial() -> void:
	_tandai_sudah_dilihat()
	selesai.emit()
	tutup()


func _unhandled_input(event: InputEvent) -> void:
	if not _terbuka:
		return
	if event.is_action_pressed("ui_right"):
		_berikutnya()
	elif event.is_action_pressed("ui_left"):
		_sebelumnya()
	elif event.is_action_pressed("ui_cancel"):
		_lewati()


## Geser kiri atau kanan untuk pindah halaman (HP)
func _gui_input(event: InputEvent) -> void:
	if not _terbuka:
		return

	var ditekan: bool = false
	var posisi: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		ditekan = st.pressed
		posisi = st.position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		ditekan = mb.pressed
		posisi = mb.position
	else:
		return

	if ditekan:
		_sentuh_aktif = true
		_sentuh_x = posisi.x
	elif _sentuh_aktif:
		_sentuh_aktif = false
		var dx: float = posisi.x - _sentuh_x
		if dx <= -jarak_swipe:
			_berikutnya()
		elif dx >= jarak_swipe:
			_sebelumnya()


# ---------------------------------------------------------------
# Buka dan tutup
# ---------------------------------------------------------------
func buka() -> void:
	if _terbuka:
		return
	_terbuka = true
	_rapikan_ukuran()
	visible = true
	modulate.a = 0.0
	_tampilkan(0)

	if _tween_buka and _tween_buka.is_valid():
		_tween_buka.kill()
	_tween_buka = create_tween()
	_tween_buka.tween_property(self, "modulate:a", 1.0, durasi_ganti_halaman * 1.5)
	dibuka.emit()


func tutup() -> void:
	if not _terbuka:
		return
	_terbuka = false
	ditutup.emit()

	if _tween_buka and _tween_buka.is_valid():
		_tween_buka.kill()
	_tween_buka = create_tween()
	_tween_buka.tween_property(self, "modulate:a", 0.0, 0.25)
	_tween_buka.tween_callback(func(): visible = false)


# ---------------------------------------------------------------
# Ingat bahwa tutorial sudah pernah dilihat
# ---------------------------------------------------------------
func _sudah_dilihat() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(FILE_TUTORIAL) != OK:
		return false
	return bool(cfg.get_value("tutorial", "sudah_dilihat", false))


func _tandai_sudah_dilihat() -> void:
	var cfg := ConfigFile.new()
	cfg.load(FILE_TUTORIAL)
	cfg.set_value("tutorial", "sudah_dilihat", true)
	cfg.save(FILE_TUTORIAL)
