extends Control
## Panel pengaturan: Audio, Grafis, Gameplay, dan Kontrol.
## Isi panel dibuat seluruhnya oleh script, jadi node lama di scene boleh dihapus.
## Dipakai PauseMenu lewat buka(), tutup(), dan sinyal ditutup.
## Semua ukuran bisa diatur dari Inspector. Nilai dalam satuan dasar, lalu dikali skala layar.

signal dibuka
signal ditutup


@export_category("Animasi Buka dan Tutup")
@export var durasi_buka: float = 0.45
@export var durasi_tutup: float = 0.25
@export var geser_vertikal: float = 60.0
@export var kedip_layar: int = 4
@export var jeda_antar_baris: float = 0.04

@export_category("Efek Slider")
@export var suara_tick: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_tick: float = -8.0
@export var jeda_tick: float = 0.06

@export_category("Layout Dasar")
## Tinggi layar acuan. Makin kecil nilainya, makin besar semua ukuran terlihat.
@export var ukuran_acuan_tinggi: float = 1080.0
## Pengali semua ukuran sekaligus. 1.2 = 20% lebih besar.
@export var skala_tambahan: float = 1.0
@export var skala_min: float = 0.6
@export var skala_maks: float = 1.6
@export var padding_horizontal_persen: float = 0.06
@export var padding_vertikal_persen: float = 0.04
## Jarak minimum tepi layar (px dasar)
@export var padding_minimum: float = 16.0
@export var jarak_wadah: int = 12

@export_category("Warna")
@export var warna_latar: Color = Color(0.06, 0.06, 0.07, 0.94)
@export var warna_aksen: Color = Color8(255, 214, 102)
@export var warna_teks: Color = Color8(235, 232, 220)
@export var warna_redup: Color = Color8(160, 160, 170)

@export_category("Judul")
@export var ukuran_judul: int = 48
@export var tebal_outline_judul: int = 6

@export_category("Tab")
@export var ukuran_font_tab: int = 22
@export var tinggi_tab: int = 68
@export var jarak_antar_tab: int = 6

@export_category("Tombol Bawah")
@export var ukuran_font_tombol: int = 24
@export var tinggi_tombol: int = 80
@export var jarak_antar_tombol: int = 12

@export_category("Baris Pengaturan")
## Tinggi slider, pilihan, dan toggle (px dasar)
@export var tinggi_kontrol: int = 80
@export var ukuran_font_seksi: int = 24
@export var ukuran_font_label: int = 26
@export var ukuran_font_nilai: int = 26
@export var ukuran_font_pilihan: int = 24
@export var ukuran_font_toggle: int = 26
@export var ukuran_font_catatan: int = 20
@export var jarak_dalam_kotak: int = 6
@export var jarak_antar_baris_isi: int = 16

@export_category("Daftar Dropdown")
## Ukuran tulisan pilihan di dalam daftar yang terbuka
@export var ukuran_font_daftar: int = 26
## Jarak vertikal antar pilihan di dalam daftar
@export var jarak_item_daftar: int = 18
## Jarak tulisan dari tepi kiri dan kanan daftar
@export var padding_item_daftar: int = 18
## Lebar maksimum ikon lingkaran di sebelah kiri setiap pilihan
@export var ukuran_ikon_daftar: int = 26

const NAMA_TAB: PackedStringArray = ["PENGATURAN_TAB_AUDIO", "PENGATURAN_TAB_GRAFIS", "PENGATURAN_TAB_GAMEPLAY", "PENGATURAN_TAB_KONTROL"]
const OPSI_PRESET: PackedStringArray = ["PRESET_RENDAH", "PRESET_SEDANG", "PRESET_TINGGI", "PRESET_KUSTOM"]
const OPSI_RESOLUSI: PackedStringArray = ["50%", "67%", "80%", "100%"]
const OPSI_BAYANGAN: PackedStringArray = ["BAYANGAN_RENDAH", "BAYANGAN_SEDANG", "BAYANGAN_TINGGI"]
const OPSI_FPS: PackedStringArray = ["30 FPS", "60 FPS", "FPS_TANPA_BATAS"]
const OPSI_BAHASA: PackedStringArray = ["Indonesia", "English"]

var _latar: ColorRect
var _wadah: VBoxContainer
var _judul: Label
var _tab_bar: HBoxContainer
var _tab_tombol: Array[Button] = []
var _scroll: ScrollContainer
var _isi: VBoxContainer
var _footer: HBoxContainer
var _btn_reset: Button
var _btn_kembali: Button
var _tombol_ui: Array[Button] = []
var _kontrol: Dictionary = {}
var _label_nilai: Dictionary = {}
var _tab_aktif: int = 0
var _geser: float = 0.0
var _tween: Tween
var _terbuka: bool = false
var _tick_timer: float = 0.0
var _tick_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	# Bersihkan isi lama dari scene, semua dibangun ulang oleh script
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_bangun_ui()

	_tick_player = AudioStreamPlayer.new()
	_tick_player.stream = suara_tick
	_tick_player.volume_db = volume_db_tick
	_tick_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	add_child(_tick_player)

	Pengaturan.berubah.connect(_saat_nilai_berubah)
	get_viewport().size_changed.connect(_rapikan_layout)
	_rapikan_layout()


func _process(delta: float) -> void:
	if _tick_timer > 0.0:
		_tick_timer -= delta


# ---------------------------------------------------------------
# Skala dan ukuran
# ---------------------------------------------------------------
func _skala() -> float:
	var v: Vector2 = get_viewport_rect().size
	if v.y <= 0.0:
		return skala_tambahan
	return clampf(v.y / ukuran_acuan_tinggi, skala_min, skala_maks) * skala_tambahan


## Mengubah ukuran dasar (dari Inspector) menjadi piksel sesuai skala layar
func _px(nilai: float) -> int:
	return roundi(nilai * _skala())


## Area yang tertutup poni, notch, atau tepi sistem: (kiri, atas, kanan, bawah) dalam px viewport
func _area_aman() -> Vector4:
	var v: Vector2 = get_viewport_rect().size
	var layar: Vector2 = Vector2(DisplayServer.screen_get_size())
	if layar.x <= 0.0 or layar.y <= 0.0 or v.x <= 0.0 or v.y <= 0.0:
		return Vector4.ZERO
	var potong: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var rasio: Vector2 = v / layar
	var kiri: float = maxf(potong.position.x, 0.0) * rasio.x
	var atas: float = maxf(potong.position.y, 0.0) * rasio.y
	var kanan: float = maxf(layar.x - potong.end.x, 0.0) * rasio.x
	var bawah: float = maxf(layar.y - potong.end.y, 0.0) * rasio.y
	return Vector4(kiri, atas, kanan, bawah)


# ---------------------------------------------------------------
# Susunan dasar UI
# ---------------------------------------------------------------
func _bangun_ui() -> void:
	_latar = ColorRect.new()
	_latar.color = warna_latar
	_latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_latar)

	_wadah = VBoxContainer.new()
	_wadah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_wadah)

	_judul = Label.new()
	Pengaturan.daftarkan_teks(_judul, "PENGATURAN_JUDUL")
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judul.add_theme_color_override("font_color", warna_aksen)
	_judul.add_theme_color_override("font_outline_color", Color.BLACK)
	_wadah.add_child(_judul)

	# Tab memenuhi lebar layar, dibagi rata
	_tab_bar = HBoxContainer.new()
	_tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wadah.add_child(_tab_bar)
	for i in NAMA_TAB.size():
		var b: Button = _buat_tombol(NAMA_TAB[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_pilih_tab.bind(i))
		_tab_bar.add_child(b)
		_tab_tombol.append(b)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_wadah.add_child(_scroll)

	_isi = VBoxContainer.new()
	_isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_isi)

	# Dua tombol bawah sama lebar
	_footer = HBoxContainer.new()
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wadah.add_child(_footer)

	_btn_reset = _buat_tombol("UI_ATUR_ULANG")
	_btn_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_reset.clip_text = true
	_btn_reset.pressed.connect(_atur_ulang)
	_footer.add_child(_btn_reset)

	_btn_kembali = _buat_tombol("UI_KEMBALI")
	_btn_kembali.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_kembali.clip_text = true
	_btn_kembali.pressed.connect(tutup)
	_footer.add_child(_btn_kembali)


func _buat_tombol(teks: String) -> Button:
	var b := Button.new()
	Pengaturan.daftarkan_teks(b, teks)
	b.mouse_entered.connect(_hover.bind(b, 1.05))
	b.mouse_exited.connect(_hover.bind(b, 1.0))
	_tombol_ui.append(b)
	return b


func _rapikan_layout() -> void:
	_judul.add_theme_font_size_override("font_size", _px(ukuran_judul))
	_judul.add_theme_constant_override("outline_size", _px(tebal_outline_judul))
	_tab_bar.add_theme_constant_override("separation", _px(jarak_antar_tab))
	_wadah.add_theme_constant_override("separation", _px(jarak_wadah))
	_isi.add_theme_constant_override("separation", _px(jarak_antar_baris_isi))
	_footer.add_theme_constant_override("separation", _px(jarak_antar_tombol))

	for b: Button in _tombol_ui:
		if b.get_parent() == _tab_bar:
			b.add_theme_font_size_override("font_size", _px(ukuran_font_tab))
			b.custom_minimum_size = Vector2(0.0, _px(tinggi_tab))
		else:
			b.add_theme_font_size_override("font_size", _px(ukuran_font_tombol))
			b.custom_minimum_size = Vector2(0.0, _px(tinggi_tombol))

	_terapkan_margin()
	_bangun_isi_tab(false)


func _terapkan_margin() -> void:
	var v: Vector2 = get_viewport_rect().size
	var aman: Vector4 = _area_aman()
	var pad_x: float = maxf(v.x * padding_horizontal_persen, padding_minimum * _skala())
	var pad_y: float = maxf(v.y * padding_vertikal_persen, padding_minimum * _skala())
	_wadah.offset_left = pad_x + aman.x
	_wadah.offset_right = -(pad_x + aman.z)
	_wadah.offset_top = pad_y + aman.y + _geser
	_wadah.offset_bottom = -(pad_y + aman.w) + _geser


func _set_geser(v: float) -> void:
	_geser = v
	_terapkan_margin()


# ---------------------------------------------------------------
# Tab
# ---------------------------------------------------------------
func _pilih_tab(i: int) -> void:
	_tab_aktif = i
	for k in _tab_tombol.size():
		_tab_tombol[k].modulate = warna_aksen if k == i else Color.WHITE
	_bangun_isi_tab(true)
	_scroll.scroll_vertical = 0


func _bangun_isi_tab(animasi: bool) -> void:
	for c in _isi.get_children():
		_isi.remove_child(c)
		c.queue_free()
	_kontrol.clear()
	_label_nilai.clear()

	match _tab_aktif:
		0: _isi_audio()
		1: _isi_grafis()
		2: _isi_gameplay()
		3: _isi_kontrol()

	_segarkan_kontrol()
	if animasi:
		_animasi_baris.call_deferred()


func _animasi_baris() -> void:
	var urutan: int = 0
	for c in _isi.get_children():
		if c is Control:
			var ctrl: Control = c
			ctrl.pivot_offset = ctrl.size * 0.5
			_munculkan(ctrl, urutan * jeda_antar_baris)
			urutan += 1


# ---------------------------------------------------------------
# Isi tiap tab
# ---------------------------------------------------------------
func _isi_audio() -> void:
	_judul_seksi("PENGATURAN_SEKSI_VOLUME")
	_tambah_slider("PENGATURAN_MASTER", "vol_master", 0.0, 1.0, 0.01)
	_tambah_slider("PENGATURAN_MUSIK", "vol_musik", 0.0, 1.0, 0.01)
	_tambah_slider("PENGATURAN_EFEK_SUARA", "vol_sfx", 0.0, 1.0, 0.01)


func _isi_grafis() -> void:
	_judul_seksi("PENGATURAN_SEKSI_PRESET")
	_tambah_pilihan("PENGATURAN_KUALITAS_GRAFIS", "preset_grafis", OPSI_PRESET)

	_judul_seksi("PENGATURAN_SEKSI_TAMPILAN")
	_tambah_pilihan("PENGATURAN_RESOLUSI", "resolusi_render", OPSI_RESOLUSI)
	_catatan("PENGATURAN_CATATAN_RESOLUSI")

	_judul_seksi("PENGATURAN_SEKSI_BAYANGAN")
	_tambah_toggle("PENGATURAN_BAYANGAN", "bayangan")
	_tambah_pilihan("PENGATURAN_KUALITAS_BAYANGAN", "kualitas_bayangan", OPSI_BAYANGAN)
	_tambah_toggle("PENGATURAN_GLOW", "glow")
	_tambah_toggle("PENGATURAN_SSAO", "ssao")

	_judul_seksi("PENGATURAN_SEKSI_PERFORMA")
	_tambah_pilihan("PENGATURAN_BATAS_FPS", "batas_fps", OPSI_FPS)


func _isi_gameplay() -> void:
	_judul_seksi("PENGATURAN_SEKSI_RADIO")
	_tambah_slider("PENGATURAN_KECEPATAN_TUNING", "kecepatan_tuning", 0.5, 1.5, 0.1)

	_judul_seksi("PENGATURAN_SEKSI_KAMERA")
	_tambah_slider("PENGATURAN_GETARAN_KAMERA", "getaran_kamera", 0.0, 2.0, 0.1)
	_tambah_toggle("PENGATURAN_GLITCH_JUDUL", "efek_glitch")


func _isi_kontrol() -> void:
	_judul_seksi("PENGATURAN_SEKSI_BAHASA")
	_tambah_pilihan("PENGATURAN_BAHASA", "bahasa", OPSI_BAHASA)

	_judul_seksi("PENGATURAN_SEKSI_SENTUHAN")
	_tambah_slider("PENGATURAN_UKURAN_TOMBOL", "ukuran_tombol", 0.7, 1.5, 0.05)
	_tambah_toggle("PENGATURAN_HAPTIC", "getar_haptic")


# ---------------------------------------------------------------
# Pembuat baris
# ---------------------------------------------------------------
func _judul_seksi(teks: String) -> void:
	var l := Label.new()
	l.text = tr(teks)
	l.add_theme_color_override("font_color", warna_aksen)
	l.add_theme_font_size_override("font_size", _px(ukuran_font_seksi))
	_isi.add_child(l)


func _catatan(teks: String) -> void:
	var l := Label.new()
	l.text = tr(teks)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", warna_redup)
	l.add_theme_font_size_override("font_size", _px(ukuran_font_catatan))
	_isi.add_child(l)


func _tambah_slider(judul: String, kunci: String, minv: float, maxv: float, langkah: float) -> void:
	var kotak := VBoxContainer.new()
	kotak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kotak.add_theme_constant_override("separation", _px(jarak_dalam_kotak))

	var baris := HBoxContainer.new()
	baris.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.text = tr(judul)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", warna_teks)
	lbl.add_theme_font_size_override("font_size", _px(ukuran_font_label))
	baris.add_child(lbl)

	var nilai_lbl := Label.new()
	nilai_lbl.add_theme_color_override("font_color", warna_aksen)
	nilai_lbl.add_theme_font_size_override("font_size", _px(ukuran_font_nilai))
	baris.add_child(nilai_lbl)
	kotak.add_child(baris)

	var slider := HSlider.new()
	slider.min_value = minv
	slider.max_value = maxv
	slider.step = langkah
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0.0, _px(tinggi_kontrol))
	slider.value_changed.connect(_saat_slider.bind(kunci))
	kotak.add_child(slider)

	_kontrol[kunci] = slider
	_label_nilai[kunci] = nilai_lbl
	_isi.add_child(kotak)


func _tambah_pilihan(judul: String, kunci: String, opsi: PackedStringArray) -> void:
	var kotak := VBoxContainer.new()
	kotak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kotak.add_theme_constant_override("separation", _px(jarak_dalam_kotak))

	var lbl := Label.new()
	lbl.text = tr(judul)
	lbl.add_theme_color_override("font_color", warna_teks)
	lbl.add_theme_font_size_override("font_size", _px(ukuran_font_label))
	kotak.add_child(lbl)

	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.custom_minimum_size = Vector2(0.0, _px(tinggi_kontrol))
	ob.add_theme_font_size_override("font_size", _px(ukuran_font_pilihan))

	# Daftar yang muncul saat dropdown dibuka (PopupMenu) diatur terpisah
	var daftar: PopupMenu = ob.get_popup()
	daftar.add_theme_font_size_override("font_size", _px(ukuran_font_daftar))
	daftar.add_theme_constant_override("v_separation", _px(jarak_item_daftar))
	daftar.add_theme_constant_override("item_start_padding", _px(padding_item_daftar))
	daftar.add_theme_constant_override("item_end_padding", _px(padding_item_daftar))
	daftar.add_theme_constant_override("icon_max_width", _px(ukuran_ikon_daftar))

	for i in opsi.size():
		ob.add_item(tr(opsi[i]), i)
	ob.item_selected.connect(_saat_pilihan.bind(kunci))
	kotak.add_child(ob)

	_kontrol[kunci] = ob
	_isi.add_child(kotak)


func _tambah_toggle(judul: String, kunci: String) -> void:
	var cb := CheckButton.new()
	cb.text = tr(judul)
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cb.custom_minimum_size = Vector2(0.0, _px(tinggi_kontrol))
	cb.add_theme_font_size_override("font_size", _px(ukuran_font_toggle))
	cb.toggled.connect(_saat_toggle.bind(kunci))
	_kontrol[kunci] = cb
	_isi.add_child(cb)


# ---------------------------------------------------------------
# Sinkron nilai dengan kontrol
# ---------------------------------------------------------------
func _segarkan_kontrol() -> void:
	for k in _kontrol.keys():
		var kunci: String = k
		var v: Variant = Pengaturan.get_nilai(kunci)
		var c: Control = _kontrol[kunci]

		if c is HSlider:
			(c as HSlider).set_value_no_signal(float(v))
		elif c is OptionButton:
			(c as OptionButton).select(int(v))
		elif c is CheckButton:
			(c as CheckButton).set_pressed_no_signal(bool(v))

		if _label_nilai.has(kunci):
			(_label_nilai[kunci] as Label).text = _format(kunci, float(v))


func _saat_nilai_berubah(_kunci: String) -> void:
	_segarkan_kontrol()


func _format(kunci: String, v: float) -> String:
	if kunci.begins_with("vol_") or kunci == "getaran_kamera" or kunci == "ukuran_tombol":
		return "%d%%" % roundi(v * 100.0)
	if kunci == "kecepatan_tuning":
		return "%.1fx" % v
	return str(v)


# ---------------------------------------------------------------
# Handler input
# ---------------------------------------------------------------
func _saat_slider(v: float, kunci: String) -> void:
	Pengaturan.atur(kunci, v)

	# Slider sedikit membesar setiap nilainya berubah
	var slider: HSlider = _kontrol.get(kunci) as HSlider
	if slider:
		slider.pivot_offset = slider.size * 0.5
		var t := create_tween()
		t.tween_property(slider, "scale", Vector2(1.02, 1.02), 0.05)
		t.tween_property(slider, "scale", Vector2.ONE, 0.08)

	# Bunyi tick hanya untuk slider volume
	if kunci.begins_with("vol_") and suara_tick and _tick_timer <= 0.0:
		_tick_player.pitch_scale = 0.9 + v * 0.3
		_tick_player.play()
		_tick_timer = jeda_tick


func _saat_pilihan(idx: int, kunci: String) -> void:
	if kunci == "preset_grafis":
		Pengaturan.terapkan_preset(idx)
	elif kunci == "bahasa":
		Pengaturan.set_bahasa(idx)
		_bangun_isi_tab(false)  # label tab KONTROL ikut berganti
	else:
		Pengaturan.atur(kunci, idx)


func _saat_toggle(on: bool, kunci: String) -> void:
	Pengaturan.atur(kunci, on)
	if kunci == "getar_haptic" and on:
		Input.vibrate_handheld(60)


func _atur_ulang() -> void:
	Pengaturan.reset_default()


# ---------------------------------------------------------------
# Buka & tutup
# ---------------------------------------------------------------
func buka() -> void:
	if _terbuka:
		return
	_terbuka = true
	dibuka.emit()
	visible = true
	modulate.a = 1.0
	_geser = geser_vertikal
	_terapkan_margin()
	_wadah.modulate.a = 0.0

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()

	# Layar berkedip seperti radio yang baru menyala
	for i in kedip_layar:
		_tween.tween_property(self, "modulate:a", randf_range(0.25, 0.85), 0.035)
	_tween.tween_property(self, "modulate:a", 1.0, 0.035)

	# Isi panel meluncur naik dengan pantulan
	_tween.tween_property(_wadah, "modulate:a", 1.0, durasi_buka * 0.5)
	_tween.parallel().tween_method(_set_geser, geser_vertikal, 0.0, durasi_buka) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_bangun_isi_tab(true)
	_scroll.scroll_vertical = 0


func tutup() -> void:
	if not _terbuka:
		return
	_terbuka = false
	ditutup.emit()
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_wadah, "modulate:a", 0.0, durasi_tutup)
	_tween.parallel().tween_method(_set_geser, 0.0, geser_vertikal, durasi_tutup) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, durasi_tutup)
	_tween.tween_callback(func(): visible = false)


func _munculkan(c: Control, tunda: float) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.9, 0.9)
	var t := create_tween()
	t.tween_interval(tunda)
	t.set_parallel(true)
	t.tween_property(c, "modulate:a", 1.0, 0.25)
	t.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hover(c: Control, skala: float) -> void:
	c.pivot_offset = c.size * 0.5
	var t := create_tween()
	t.tween_property(c, "scale", Vector2(skala, skala), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
