extends Control
## Panel pilih kesulitan. Seluruh layout, kartu, dan tombol dibangun oleh script.
## Node lama di scene (IsiPanel, Kartu0-3, BtnMasuk, BtnKembaliKesulitan) tidak dipakai lagi.
## Font dan gambar diambil dari scene lama kalau Inspector kosong.
## Semua ukuran mengikuti tinggi layar, jadi sama di PC maupun HP landscape.
## Semua teks harus berupa key terjemahan (misalnya KESULITAN_DESK_0), bukan kalimat langsung.
## Teks ikut berganti bahasa, termasuk saat bahasa diganti dengan panel ini sedang terbuka.

signal dibuka
signal ditutup
signal konfirmasi(indeks: int)

const JUMLAH_KARTU: int = 4
## Set ke false untuk mematikan log debug bahasa
const DEBUG_BAHASA: bool = false

@export_category("Isi Kesulitan")
@export var nama_kesulitan: Array[String] = ["KESULITAN_NAMA_0", "KESULITAN_NAMA_1", "KESULITAN_NAMA_2", "KESULITAN_NAMA_3"]
@export var deskripsi_kesulitan: Array[String] = [
	"KESULITAN_DESK_0",
	"KESULITAN_DESK_1",
	"KESULITAN_DESK_2",
	"KESULITAN_DESK_3",
]
@export var ilustrasi_kesulitan: Array[Texture2D] = []
@export var warna_kesulitan: Array[Color] = [
	Color(0.55, 0.78, 0.6),
	Color(0.9, 0.9, 0.9),
	Color(1.0, 0.6, 0.25),
	Color(0.9, 0.2, 0.22),
]

@export_category("Teks")
@export var judul_teks: String = "KESULITAN_JUDUL"
@export var teks_pilih: String = "KESULITAN_PILIH"
@export var teks_terpilih: String = "KESULITAN_TERPILIH"
@export var teks_masuk: String = "KESULITAN_MAINKAN"
@export var teks_kembali: String = "UI_KEMBALI"
## Kosongkan untuk memakai font dari scene lama
@export var font_utama: Font

@export_category("Layout")
## Tinggi layar acuan. Pada tinggi ini semua ukuran memakai angka dasar.
@export var ukuran_acuan_tinggi: float = 900.0
@export_range(0.0, 0.3, 0.01) var margin_horizontal: float = 0.06
@export_range(0.0, 0.3, 0.01) var margin_vertikal: float = 0.07
@export_range(0.0, 1.0, 0.05) var latar_gelap: float = 0.55

@export_category("Warna")
@export var warna_teks: Color = Color(0.92, 0.9, 0.86)
@export var warna_kartu: Color = Color(0.05, 0.05, 0.06, 0.9)
@export var warna_kartu_terpilih: Color = Color(0.12, 0.12, 0.13, 0.96)
@export_range(0.0, 1.0, 0.05) var redup_kartu: float = 0.45

@export_category("Animasi")
@export var durasi_pilih: float = 0.18
@export var jumlah_glitch: int = 8
@export var kekuatan_glitch: float = 14.0
@export var durasi_step_glitch: float = 0.045
@export var durasi_panel_tutup: float = 0.2

@export_category("Suara")
@export var suara_klik: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_klik: float = -6.0

# Elemen UI yang dibangun script
var _latar: ColorRect
var _konten: VBoxContainer
var _judul: Label
var _baris: HBoxContainer
var _footer: HBoxContainer
var _btn_masuk: Button
var _btn_kembali: Button

var _kartu: Array[PanelContainer] = []
var _stil_kartu: Array[StyleBoxFlat] = []
var _margin_kartu: Array[MarginContainer] = []
var _ikon_kartu: Array[TextureRect] = []
var _label_nama: Array[Label] = []
var _label_desk: Array[Label] = []
var _tombol_kartu: Array[Button] = []
var _tween_kartu: Array[Tween] = []
var _hover_kartu: Array[bool] = []

# Data dari scene lama, dipakai kalau Inspector kosong
var _ikon_scene: Array[Texture2D] = []
var _font_scene: Font = null

var _indeks_terpilih: int = 1
var _terbuka: bool = false
var _tween: Tween
var _player_klik: AudioStreamPlayer

# Offset dasar _konten, dipakai untuk efek glitch
var _base_kiri: float = 0.0
var _base_atas: float = 0.0
var _base_kanan: float = 0.0
var _base_bawah: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_ambil_dari_scene_lama()

	# Bersihkan node lama, semua dibangun ulang oleh script
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_player_klik = AudioStreamPlayer.new()
	_player_klik.stream = suara_klik
	_player_klik.volume_db = volume_db_klik
	_player_klik.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	add_child(_player_klik)

	_bangun_ui()
	get_viewport().size_changed.connect(_rapikan_ukuran)
	_rapikan_ukuran()
	_pilih(1, false)
	Pengaturan.berubah.connect(_saat_pengaturan_berubah)
	_debug_bahasa("_ready")


# ---------------------------------------------------------------
# Ambil data dari scene lama (sebelum dihapus)
# Hanya ikon dan font yang diambil. Teks tidak diambil dari scene lama,
# karena teks di sana berbahasa Indonesia dan tidak bisa diterjemahkan.
# ---------------------------------------------------------------
func _ambil_dari_scene_lama() -> void:
	_ikon_scene.resize(JUMLAH_KARTU)
	for i in JUMLAH_KARTU:
		_ikon_scene[i] = null
		var k := find_child("Kartu%d" % i, true, false) as Control
		if k == null:
			continue
		var gbr := k.find_child("Ilustrasi", true, false) as TextureRect
		if gbr:
			_ikon_scene[i] = gbr.texture
		if _font_scene == null:
			var lbl := k.find_child("LabelDeskripsi", true, false) as Label
			if lbl:
				_font_scene = lbl.get_theme_font("font")


func _ikon_untuk(i: int) -> Texture2D:
	if i < ilustrasi_kesulitan.size() and ilustrasi_kesulitan[i] != null:
		return ilustrasi_kesulitan[i]
	return _ikon_scene[i]


## Hanya memakai key dari Inspector. Kalau kosong, kembalikan string kosong.
func _teks_deskripsi(i: int) -> String:
	if i < deskripsi_kesulitan.size():
		return deskripsi_kesulitan[i]
	return ""


func _nama_untuk(i: int) -> String:
	if i < nama_kesulitan.size():
		return nama_kesulitan[i]
	return ""


func _warna_kesulitan(i: int) -> Color:
	if i < warna_kesulitan.size():
		return warna_kesulitan[i]
	return warna_teks


func _pasang_font(c: Control) -> void:
	if font_utama:
		c.add_theme_font_override("font", font_utama)
	elif _font_scene:
		c.add_theme_font_override("font", _font_scene)


func _skala() -> float:
	var v: Vector2 = get_viewport_rect().size
	if v.y <= 0.0:
		return 1.0
	return clampf(v.y / ukuran_acuan_tinggi, 0.7, 1.6)


# ---------------------------------------------------------------
# Debug bahasa
# ---------------------------------------------------------------
func _debug_bahasa(sumber: String) -> void:
	if not DEBUG_BAHASA:
		return
	print("[DEBUG BAHASA] (%s) locale=%s" % [sumber, TranslationServer.get_locale()])
	print("[DEBUG BAHASA]   judul_teks = '%s' -> '%s'" % [judul_teks, tr(judul_teks)])
	print("[DEBUG BAHASA]   teks_masuk = '%s' -> '%s'" % [teks_masuk, tr(teks_masuk)])
	print("[DEBUG BAHASA]   nama[0]    = '%s' -> '%s'" % [_nama_untuk(0), tr(_nama_untuk(0))])
	print("[DEBUG BAHASA]   desk[0]    = '%s' -> '%s'" % [_teks_deskripsi(0), tr(_teks_deskripsi(0))])
	if tr(_teks_deskripsi(0)) == _teks_deskripsi(0) and _teks_deskripsi(0) != "":
		print("[DEBUG BAHASA]   PERINGATAN: key '%s' tidak ditemukan di terjemahan (tr mengembalikan key apa adanya)" % _teks_deskripsi(0))


# ---------------------------------------------------------------
# Membangun UI
# ---------------------------------------------------------------
func _bangun_ui() -> void:
	_latar = ColorRect.new()
	_latar.color = Color(0, 0, 0, latar_gelap)
	_latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_latar)

	_konten = VBoxContainer.new()
	_konten.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_konten.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_konten)

	_judul = Label.new()
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_judul.add_theme_color_override("font_color", warna_teks)
	_pasang_font(_judul)
	_konten.add_child(_judul)

	_baris = HBoxContainer.new()
	_baris.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_konten.add_child(_baris)
	for i in JUMLAH_KARTU:
		_baris.add_child(_buat_kartu(i))

	_footer = HBoxContainer.new()
	_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_konten.add_child(_footer)

	_btn_kembali = _buat_tombol_utama(teks_kembali)
	_btn_kembali.pressed.connect(tutup)
	_footer.add_child(_btn_kembali)

	var sela := Control.new()
	sela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer.add_child(sela)

	_btn_masuk = _buat_tombol_utama(teks_masuk)
	_btn_masuk.pressed.connect(_konfirmasi)
	_footer.add_child(_btn_masuk)


func _buat_kartu(i: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(_input_kartu.bind(i))
	p.mouse_entered.connect(_hover_kartu_masuk.bind(i, true))
	p.mouse_exited.connect(_hover_kartu_masuk.bind(i, false))

	var stil := StyleBoxFlat.new()
	p.add_theme_stylebox_override("panel", stil)
	_stil_kartu.append(stil)
	_kartu.append(p)
	_tween_kartu.append(null)
	_hover_kartu.append(false)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(margin)
	_margin_kartu.append(margin)

	var v := VBoxContainer.new()
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var ikon := TextureRect.new()
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ikon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ikon.texture = _ikon_untuk(i)
	ikon.visible = ikon.texture != null
	v.add_child(ikon)
	_ikon_kartu.append(ikon)

	var nama := Label.new()
	nama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pasang_font(nama)
	v.add_child(nama)
	_label_nama.append(nama)

	var desk := Label.new()
	desk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desk.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pasang_font(desk)
	v.add_child(desk)
	_label_desk.append(desk)

	var tombol := Button.new()
	tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tombol.pressed.connect(_pilih.bind(i))
	_pasang_font(tombol)
	_efek_tombol_pasang(tombol)
	v.add_child(tombol)
	_tombol_kartu.append(tombol)

	return p


func _buat_tombol_utama(teks: String) -> Button:
	var b := Button.new()
	b.text = tr(teks)
	_pasang_font(b)
	_efek_tombol_pasang(b)
	return b


# ---------------------------------------------------------------
# Ukuran responsif (PC dan HP landscape)
# ---------------------------------------------------------------
func _rapikan_ukuran() -> void:
	var v: Vector2 = get_viewport_rect().size
	var s: float = _skala()
	var pad_x: float = maxf(v.x * margin_horizontal, 16.0)
	var pad_y: float = maxf(v.y * margin_vertikal, 12.0)

	_base_kiri = pad_x
	_base_atas = pad_y
	_base_kanan = -pad_x
	_base_bawah = -pad_y
	_kembali_normal()
	_konten.add_theme_constant_override("separation", roundi(24.0 * s))

	_judul.add_theme_font_size_override("font_size", roundi(54.0 * s))
	_baris.add_theme_constant_override("separation", roundi(18.0 * s))

	for i in JUMLAH_KARTU:
		var m: MarginContainer = _margin_kartu[i]
		m.add_theme_constant_override("margin_left", roundi(18.0 * s))
		m.add_theme_constant_override("margin_right", roundi(18.0 * s))
		m.add_theme_constant_override("margin_top", roundi(16.0 * s))
		m.add_theme_constant_override("margin_bottom", roundi(16.0 * s))

		_ikon_kartu[i].custom_minimum_size = Vector2(0.0, roundi(120.0 * s))

		_label_nama[i].add_theme_font_size_override("font_size", roundi(34.0 * s))
		_label_nama[i].add_theme_color_override("font_color", _warna_kesulitan(i))

		_label_desk[i].add_theme_font_size_override("font_size", roundi(22.0 * s))
		_label_desk[i].add_theme_color_override("font_color", warna_teks)

		_tombol_kartu[i].add_theme_font_size_override("font_size", roundi(24.0 * s))
		_tombol_kartu[i].custom_minimum_size = Vector2(0.0, roundi(56.0 * s))

		_segarkan_kartu(i, false)

	_footer.add_theme_constant_override("separation", roundi(20.0 * s))
	for b in [_btn_kembali, _btn_masuk]:
		b.add_theme_font_size_override("font_size", roundi(26.0 * s))
		b.custom_minimum_size = Vector2(roundi(220.0 * s), roundi(64.0 * s))

	_segarkan_teks()
	_segarkan_footer()


# ---------------------------------------------------------------
# Teks (diterjemahkan ulang setiap panel dibuka dan saat bahasa berganti)
# ---------------------------------------------------------------
func _segarkan_teks() -> void:
	_judul.text = tr(judul_teks)
	for i in JUMLAH_KARTU:
		_label_nama[i].text = tr(_nama_untuk(i))
		_label_desk[i].text = tr(_teks_deskripsi(i))


## Dipanggil saat bahasa diganti. Panel bisa saja sedang terbuka, jadi teks harus ikut berubah langsung.
func _saat_pengaturan_berubah(kunci: String) -> void:
	if kunci != "bahasa" and kunci != "semua":
		return
	_debug_bahasa("saat bahasa berganti")
	_segarkan_teks()
	_segarkan_footer()
	for i in JUMLAH_KARTU:
		_segarkan_kartu(i, false)


# ---------------------------------------------------------------
# Tampilan kartu dan tombol
# ---------------------------------------------------------------
func _segarkan_kartu(i: int, animasi: bool) -> void:
	var s: float = _skala()
	var terpilih: bool = i == _indeks_terpilih
	var warna: Color = _warna_kesulitan(i)

	var stil: StyleBoxFlat = _stil_kartu[i]
	stil.bg_color = warna_kartu_terpilih if terpilih else warna_kartu
	stil.border_color = warna if terpilih else Color(warna.r, warna.g, warna.b, 0.35)
	stil.set_border_width_all(roundi((3.0 if terpilih else 1.0) * s))
	stil.set_corner_radius_all(roundi(10.0 * s))

	# Kartu yang tidak dipilih sedikit redup, kartu yang disorot sedikit lebih terang
	var target: Color = Color(1, 1, 1, 1)
	if not terpilih:
		target = Color(0.75, 0.75, 0.75, 1.0 - redup_kartu)
		if _hover_kartu[i]:
			target = Color(0.92, 0.92, 0.92, 1.0 - redup_kartu * 0.5)

	var kartu: PanelContainer = _kartu[i]
	if animasi:
		if _tween_kartu[i] and _tween_kartu[i].is_valid():
			_tween_kartu[i].kill()
		var t := create_tween()
		t.tween_property(kartu, "modulate", target, durasi_pilih)
		_tween_kartu[i] = t
	else:
		kartu.modulate = target

	var b: Button = _tombol_kartu[i]
	b.text = tr(teks_terpilih) if terpilih else tr(teks_pilih)
	_gaya_tombol(b, warna, terpilih)


func _segarkan_footer() -> void:
	var warna: Color = _warna_kesulitan(_indeks_terpilih)
	_btn_masuk.text = tr(teks_masuk)
	_gaya_tombol(_btn_masuk, warna, true)
	_btn_kembali.text = tr(teks_kembali)
	_gaya_tombol(_btn_kembali, Color(0.75, 0.75, 0.75), false)


## terisi = tombol penuh (kartu terpilih / MAINKAN), kalau tidak tombol garis tepi
func _gaya_tombol(b: Button, warna: Color, terisi: bool) -> void:
	var s: float = _skala()
	var r: int = roundi(8.0 * s)
	var bg: Color = warna if terisi else Color(0, 0, 0, 0)
	var teks: Color = Color(0.06, 0.06, 0.06) if terisi else warna
	var sorot_bg: Color = warna.lightened(0.15) if terisi else Color(warna.r, warna.g, warna.b, 0.18)
	var tekan_bg: Color = warna.darkened(0.2) if terisi else Color(warna.r, warna.g, warna.b, 0.3)

	b.add_theme_stylebox_override("normal", _stil_tombol(bg, warna, r, s))
	b.add_theme_stylebox_override("hover", _stil_tombol(sorot_bg, warna, r, s))
	b.add_theme_stylebox_override("pressed", _stil_tombol(tekan_bg, warna, r, s))
	b.add_theme_stylebox_override("focus", _stil_tombol(sorot_bg, warna, r, s))
	b.add_theme_color_override("font_color", teks)
	b.add_theme_color_override("font_hover_color", teks)
	b.add_theme_color_override("font_pressed_color", teks)
	b.add_theme_color_override("font_focus_color", teks)


func _stil_tombol(bg: Color, border: Color, r: int, s: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(roundi(2.0 * s))
	sb.set_corner_radius_all(r)
	return sb


# ---------------------------------------------------------------
# Interaksi
# ---------------------------------------------------------------
func _hover_kartu_masuk(i: int, masuk: bool) -> void:
	_hover_kartu[i] = masuk
	_segarkan_kartu(i, true)


func _input_kartu(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pilih(i)


func _efek_tombol_pasang(b: Button) -> void:
	b.mouse_entered.connect(_skala_tombol.bind(b, 1.04))
	b.mouse_exited.connect(_skala_tombol.bind(b, 1.0))
	b.button_down.connect(_skala_tombol.bind(b, 0.96))
	b.button_up.connect(_skala_tombol.bind(b, 1.0))


func _skala_tombol(b: Button, skala: float) -> void:
	b.pivot_offset = b.size * 0.5
	var t := create_tween()
	t.tween_property(b, "scale", Vector2(skala, skala), 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## animasi = false dipakai saat inisialisasi
func _pilih(i: int, animasi: bool = true) -> void:
	var sebelumnya: int = _indeks_terpilih
	_indeks_terpilih = clampi(i, 0, JUMLAH_KARTU - 1)

	for j in JUMLAH_KARTU:
		_segarkan_kartu(j, animasi)
	_segarkan_footer()

	if animasi and sebelumnya != _indeks_terpilih and _player_klik.stream:
		_player_klik.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
		_player_klik.play()


func _konfirmasi() -> void:
	konfirmasi.emit(_indeks_terpilih)


# ---------------------------------------------------------------
# Buka dan tutup
# ---------------------------------------------------------------
func buka() -> void:
	if _terbuka:
		return
	_terbuka = true
	dibuka.emit()

	if _tween and _tween.is_valid():
		_tween.kill()

	visible = true
	modulate.a = 1.0
	_rapikan_ukuran()

	# Glitch masuk: getaran dan kedip makin lama makin kecil
	_konten.modulate.a = 0.0
	_tween = create_tween()
	for i in jumlah_glitch:
		var k: float = kekuatan_glitch * (1.0 - float(i) / float(jumlah_glitch))
		_tween.tween_callback(_acak_posisi.bind(k))
		_tween.tween_property(_konten, "modulate:a", randf_range(0.2, 1.0), durasi_step_glitch)
	_tween.tween_callback(_selesai_masuk)


func tutup() -> void:
	if not _terbuka:
		return
	_terbuka = false
	ditutup.emit()

	var t: Tween = animasi_keluar()
	t.tween_callback(_sembunyikan)


## Dipakai saat tombol MAINKAN ditekan, dan juga oleh tutup()
func animasi_keluar() -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()

	var t := create_tween()
	# Glitch keluar: getaran dan kedip makin lama makin besar
	for i in jumlah_glitch:
		var k: float = kekuatan_glitch * (float(i) / float(jumlah_glitch))
		t.tween_callback(_acak_posisi.bind(k))
		t.tween_property(_konten, "modulate:a", randf_range(0.0, 1.0), durasi_step_glitch)
	t.tween_property(_konten, "modulate:a", 0.0, durasi_step_glitch)

	t.tween_property(self, "modulate:a", 0.0, durasi_panel_tutup)
	_tween = t
	return t


# ---------------------------------------------------------------
# Helper glitch
# ---------------------------------------------------------------
func _acak_posisi(kekuatan: float) -> void:
	var dx: float = randf_range(-kekuatan, kekuatan)
	var dy: float = randf_range(-kekuatan * 0.25, kekuatan * 0.25)
	_konten.offset_left = _base_kiri + dx
	_konten.offset_right = _base_kanan + dx
	_konten.offset_top = _base_atas + dy
	_konten.offset_bottom = _base_bawah + dy


func _kembali_normal() -> void:
	_konten.offset_left = _base_kiri
	_konten.offset_right = _base_kanan
	_konten.offset_top = _base_atas
	_konten.offset_bottom = _base_bawah


func _selesai_masuk() -> void:
	_kembali_normal()
	_konten.modulate.a = 1.0


func _sembunyikan() -> void:
	visible = false
	modulate.a = 1.0
	_kembali_normal()
	_konten.modulate.a = 1.0
