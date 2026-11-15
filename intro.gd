extends Control

## Seret gambar headset (PNG, sebaiknya transparan) ke sini
@export var gambar_headset: Texture2D
## Seberapa terlihat headset di latar (0 = hilang, 1 = jelas)
@export_range(0.0, 1.0) var opasitas_headset: float = 0.35
## Font opsional. Kosongkan untuk memakai font default
@export var font_teks: Font
@export var ukuran_font: int = 36
## Lama teks tampil penuh sebelum menghilang (detik)
@export var durasi_tahan: float = 2.5
## Lama fade masuk dan keluar teks (detik)
@export var durasi_fade: float = 1.0
## Jeda kosong antar kalimat (detik)
@export var jeda_antar_baris: float = 0.6
## Scene yang dituju setelah intro selesai atau dilewati
@export var scene_menu: String = "res://MainMenu.tscn"

## Isi teks intro dalam bentuk key terjemahan. Satu elemen = satu layar.
var baris_teks: Array[String] = [
	"INTRO_HEADSET",
]

var _headset: TextureRect
var _teks: Label
var _sudah_pindah: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_buat_tampilan()
	_jalankan_intro()

## Membuat semua node secara otomatis, tanpa perlu diatur di editor
func _buat_tampilan() -> void:
	# Latar hitam
	var latar := ColorRect.new()
	latar.color = Color.BLACK
	latar.set_anchors_preset(Control.PRESET_FULL_RECT)
	latar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(latar)

	# Gambar headset, menyesuaikan layar tanpa gepeng
	_headset = TextureRect.new()
	_headset.texture = gambar_headset
	_headset.set_anchors_preset(Control.PRESET_FULL_RECT)
	_headset.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_headset.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_headset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_headset.modulate.a = 0.0
	add_child(_headset)

	if gambar_headset == null:
		push_warning("Gambar Headset belum diisi di Inspector.")

	# Teks di tengah dengan margin kiri-kanan
	_teks = Label.new()
	_teks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_teks.offset_left = 40.0
	_teks.offset_right = -40.0
	_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_teks.add_theme_font_size_override("font_size", ukuran_font)
	if font_teks:
		_teks.add_theme_font_override("font", font_teks)
	_teks.modulate.a = 0.0
	add_child(_teks)

func _jalankan_intro() -> void:
	# Headset muncul perlahan
	var t_headset: Tween = create_tween()
	t_headset.tween_property(_headset, "modulate:a", opasitas_headset, 2.0)
	await t_headset.finished

	# Teks tampil satu per satu, diterjemahkan sesuai bahasa yang aktif
	for kunci: String in baris_teks:
		if _sudah_pindah:
			return
		_teks.text = tr(kunci)

		var t_masuk: Tween = create_tween()
		t_masuk.tween_property(_teks, "modulate:a", 1.0, durasi_fade)
		await t_masuk.finished
		if _sudah_pindah:
			return

		await get_tree().create_timer(durasi_tahan).timeout
		if _sudah_pindah:
			return

		var t_keluar: Tween = create_tween()
		t_keluar.tween_property(_teks, "modulate:a", 0.0, durasi_fade)
		await t_keluar.finished
		await get_tree().create_timer(jeda_antar_baris).timeout

	_pindah_ke_menu()

## Tap atau klik untuk melewati intro
func _gui_input(event: InputEvent) -> void:
	var ditekan: bool = false
	if event is InputEventMouseButton:
		ditekan = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		ditekan = (event as InputEventScreenTouch).pressed

	if ditekan:
		_pindah_ke_menu()

func _pindah_ke_menu() -> void:
	if _sudah_pindah:
		return
	_sudah_pindah = true
	TransitionLayer.pindah_scene(scene_menu)
