extends CanvasLayer

@export var scene_tombol: PackedScene
@export var scene_pengaturan: PackedScene
@export var scene_menu: String = "res://MainMenu.tscn"
@export var font_judul: Font
@export var suara_klik: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_klik: float = 0.0
@export var warna_redup: Color = Color(0.0, 0.0, 0.0, 0.7)
@export var durasi_fade_keluar: float = 0.6

const RASIO_TOMBOL_PAUSE: float = 0.08  # 8% tinggi layar, kira-kira 86 px di layar 1080p

var _menu_terbuka: bool = false
var _sedang_keluar: bool = false
var _redup: ColorRect
var _pusat: VBoxContainer
var _tombol_pause: Button
var _panel = null
var _fade: ColorRect
var _audio_klik: AudioStreamPlayer
var _tombol_list: Array[Button] = []
var _audio_dijeda: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_buat_ui()
	_redup.visible = false
	_pusat.visible = false

	_audio_klik = AudioStreamPlayer.new()
	_audio_klik.stream = suara_klik
	_audio_klik.volume_db = volume_db_klik
	_audio_klik.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	add_child(_audio_klik)

func _buat_ui() -> void:
	_redup = ColorRect.new()
	_redup.color = warna_redup
	_redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_redup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_redup)

	_pusat = VBoxContainer.new()
	_pusat.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pusat.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pusat.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pusat.custom_minimum_size = Vector2(320, 0)
	_pusat.add_theme_constant_override("separation", 18)
	add_child(_pusat)

	var judul := Label.new()
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_size_override("font_size", 56)
	if font_judul:
		judul.add_theme_font_override("font", font_judul)
	Pengaturan.daftarkan_teks(judul, "PAUSE_JUDUL")
	_pusat.add_child(judul)

	_buat_tombol("PAUSE_LANJUTKAN", _lanjut)
	_buat_tombol("PAUSE_PENGATURAN", _buka_pengaturan)
	_buat_tombol("PAUSE_MENU_UTAMA", _ke_menu)

	_tombol_pause = Button.new()
	_tombol_pause.text = "II"
	_tombol_pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tombol_pause.mouse_filter = Control.MOUSE_FILTER_STOP
	_tombol_pause.pressed.connect(_buka_menu)
	add_child(_tombol_pause)
	get_viewport().size_changed.connect(_rapikan_tombol_pause)
	_rapikan_tombol_pause()

	if scene_pengaturan:
		_panel = scene_pengaturan.instantiate()
		add_child(_panel)
		_panel.visible = false
		if _panel.has_signal("ditutup"):
			_panel.ditutup.connect(_saat_panel_ditutup)
	else:
		push_warning("Scene Pengaturan belum diisi di Inspector PauseMenu")

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

## Ukuran tombol pause mengikuti tinggi layar, sama di PC dan HP
func _rapikan_tombol_pause() -> void:
	var v: Vector2 = get_viewport().get_visible_rect().size
	var ukuran: float = clampf(v.y * RASIO_TOMBOL_PAUSE, 56.0, 128.0)
	var margin: float = clampf(v.y * 0.025, 12.0, 40.0)

	_tombol_pause.custom_minimum_size = Vector2(ukuran, ukuran)
	_tombol_pause.offset_right = -margin
	_tombol_pause.offset_left = -margin - ukuran
	_tombol_pause.offset_top = margin
	_tombol_pause.offset_bottom = margin + ukuran
	_tombol_pause.add_theme_font_size_override("font_size", roundi(ukuran * 0.45))

func _buat_tombol(kunci: String, aksi: Callable) -> void:
	var b: Button = null
	if scene_tombol:
		b = scene_tombol.instantiate() as Button
	if b == null:
		push_warning("Scene Tombol belum diisi di Inspector PauseMenu, memakai tombol polos")
		b = Button.new()
		b.custom_minimum_size = Vector2(280, 56)
	Pengaturan.daftarkan_teks(b, kunci)
	b.pressed.connect(_saat_tombol_ditekan.bind(aksi))
	_pusat.add_child(b)
	_tombol_list.append(b)

func _saat_tombol_ditekan(aksi: Callable) -> void:
	if _audio_klik.stream:
		_audio_klik.play()
	aksi.call()

func _process(_delta: float) -> void:
	_tombol_pause.visible = not _menu_terbuka and not _sedang_mati()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _sedang_keluar:
		return
	if _panel and _panel.visible:
		_tutup_pengaturan()
	elif _menu_terbuka:
		_lanjut()
	else:
		_buka_menu()

func _sedang_mati() -> bool:
	return get_parent().get("sedang_mati") == true

# --- Buka / tutup pause ---

func _buka_menu() -> void:
	if _menu_terbuka or _sedang_keluar or _sedang_mati():
		return
	_menu_terbuka = true
	_redup.visible = true
	_pusat.visible = true
	_jeda_audio()
	get_tree().paused = true

func _lanjut() -> void:
	if _sedang_keluar:
		return
	_menu_terbuka = false
	_redup.visible = false
	_pusat.visible = false
	get_tree().paused = false
	_lanjutkan_audio()

# --- Pengaturan ---

func _buka_pengaturan() -> void:
	if _panel == null:
		print("INFO: Panel pengaturan belum dipasang di Inspector")
		return
	_pusat.visible = false
	if _panel.has_method("buka"):
		_panel.buka()
	else:
		_panel.visible = true

func _tutup_pengaturan() -> void:
	if _panel.has_method("tutup"):
		_panel.tutup()
	else:
		_panel.visible = false
	_pusat.visible = true

func _saat_panel_ditutup() -> void:
	_pusat.visible = true

# --- Menu Utama ---

func _ke_menu() -> void:
	if _sedang_keluar:
		return
	_sedang_keluar = true
	for b in _tombol_list:
		b.disabled = true
	_tombol_pause.visible = false
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "color:a", 1.0, durasi_fade_keluar) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_pindah_ke_menu)

func _pindah_ke_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_menu)

# --- Audio gameplay ---

func _jeda_audio() -> void:
	_audio_dijeda.clear()
	var induk := get_parent()
	var semua: Array = []
	semua.append_array(induk.find_children("*", "AudioStreamPlayer", true, false))
	semua.append_array(induk.find_children("*", "AudioStreamPlayer3D", true, false))
	for p in semua:
		if p == _audio_klik:
			continue
		if p.playing and not p.stream_paused:
			p.stream_paused = true
			_audio_dijeda.append(p)

func _lanjutkan_audio() -> void:
	for p in _audio_dijeda:
		if is_instance_valid(p):
			p.stream_paused = false
	_audio_dijeda.clear()
