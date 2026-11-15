extends CanvasLayer

## Pengaturan diambil dari file transition_settings.tres (diatur lewat Inspector)
var pengaturan: TransitionSettings = preload("res://transition_settings.tres")

var _overlay: ColorRect
var _bar: ProgressBar
var _label: Label
var _path_tujuan: String = ""
var _sedang_memuat: bool = false
var _progres: Array = []

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.color = pengaturan.warna_latar
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.modulate.a = 0.0
	_overlay.visible = false
	add_child(_overlay)

	var pusat := CenterContainer.new()
	pusat.set_anchors_preset(Control.PRESET_FULL_RECT)
	pusat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(pusat)

	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 14)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pusat.add_child(kolom)

	_label = Label.new()
	_label.text = tr(pengaturan.teks_memuat)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", pengaturan.ukuran_font)
	_label.add_theme_color_override("font_color", pengaturan.warna_teks)
	kolom.add_child(_label)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(pengaturan.lebar_bar, pengaturan.tinggi_bar)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gaya_kosong := StyleBoxFlat.new()
	gaya_kosong.bg_color = pengaturan.warna_bar_kosong
	gaya_kosong.set_corner_radius_all(pengaturan.jari_jari_sudut)

	var gaya_isi := StyleBoxFlat.new()
	gaya_isi.bg_color = pengaturan.warna_bar_isi
	gaya_isi.set_corner_radius_all(pengaturan.jari_jari_sudut)

	_bar.add_theme_stylebox_override("background", gaya_kosong)
	_bar.add_theme_stylebox_override("fill", gaya_isi)
	kolom.add_child(_bar)

## Memuat scene di background, lalu pindah saat sudah siap.
func pindah_scene(path: String) -> void:
	if _sedang_memuat:
		return
	if not ResourceLoader.exists(path):
		push_error("Scene tidak ditemukan: " + path)
		return

	_sedang_memuat = true
	_path_tujuan = path
	_bar.value = 0.0
	ResourceLoader.load_threaded_request(path)

	_overlay.visible = true
	create_tween().tween_property(_overlay, "modulate:a", 1.0, pengaturan.durasi_fade_masuk)

func _process(delta: float) -> void:
	if not _sedang_memuat:
		return

	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_path_tujuan, _progres)

	var target: float = _bar.value
	if _progres.size() > 0:
		target = _progres[0] * 100.0
	_bar.value = move_toward(_bar.value, target, delta * pengaturan.kecepatan_bar)

	var jumlah_titik: int = int(float(Time.get_ticks_msec()) / float(pengaturan.jeda_titik_ms)) % 4
	_label.text = tr(pengaturan.teks_memuat) + ".".repeat(jumlah_titik)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_sedang_memuat = false
			_bar.value = 100.0
			var scene: PackedScene = ResourceLoader.load_threaded_get(_path_tujuan)
			get_tree().change_scene_to_packed(scene)
			_buka_layar()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_sedang_memuat = false
			_overlay.visible = false
			push_error("Gagal memuat scene: " + _path_tujuan)

## Fade out setelah scene baru sempat tampil beberapa frame
func _buka_layar() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var t := create_tween()
	t.tween_property(_overlay, "modulate:a", 0.0, pengaturan.durasi_fade_keluar)
	t.tween_callback(func(): _overlay.visible = false)
