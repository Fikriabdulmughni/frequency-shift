extends Node3D

@export var scene_gameplay: String = "res://cutscene.scn"
@export var durasi_fade: float = 0.8

@export_category("Audio Tombol UI")
@export var suara_klik_tombol: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_tombol: float = 5.0
@export_range(0.0, 0.3, 0.01) var variasi_pitch_klik: float = 0.03
@export var jeda_sebelum_mulai: float = 0.1
@export var jeda_sebelum_keluar: float = 0.15

@export_category("Suara Transisi Scene")
@export var suara_transisi: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_transisi: float = -6.0
@export var transisi_tunda: float = 0.0
@export var transisi_durasi_fade_keluar: float = 0.6

@export_category("Backsound Menu")
@export var backsound: AudioStream
@export_range(-40.0, 6.0, 0.1) var volume_db_backsound: float = -10.0
@export_range(-80.0, 0.0, 0.1) var volume_db_senyap: float = -40.0

@export_subgroup("Fade Masuk")
@export var fade_masuk_tunda: float = 0.0
@export var fade_masuk_durasi: float = 1.5
@export var fade_masuk_transisi: Tween.TransitionType = Tween.TRANS_SINE
@export var fade_masuk_easing: Tween.EaseType = Tween.EASE_OUT

@export_subgroup("Fade Keluar")
@export var fade_keluar_durasi: float = 0.8
@export var fade_keluar_transisi: Tween.TransitionType = Tween.TRANS_SINE
@export var fade_keluar_easing: Tween.EaseType = Tween.EASE_IN

@export_category("Animasi Menu")
@export var durasi_sembunyi_menu: float = 0.3

@export_category("Tombol Tutorial")
## Gambar untuk tombol tanda tanya di kiri atas. Kalau kosong, dipakai tombol teks "?".
@export var gambar_tombol_tutorial: Texture2D
## Ukuran tombol sebagai porsi tinggi layar (0.085 = 8,5% tinggi layar)
@export_range(0.04, 0.2, 0.005) var rasio_tombol_tutorial: float = 0.085

const BUS_MUSIK: String = "Musik"
const BUS_SFX: String = "SFX"

var audio_ui: AudioStreamPlayer
var audio_backsound: AudioStreamPlayer
var _tween_backsound: Tween
var fade_overlay: ColorRect
var btn_mulai: Button
var btn_pengaturan: Button
var btn_kredit: Button
var btn_keluar: Button
var btn_tutorial: BaseButton
var walkie_talkie: Node3D
var judul: Label
var menu_tombol: Control
var panel_pengaturan: Node
var panel_kesulitan: Node
var panel_kredit: Node
var panel_tutorial: Node

var _scene_tujuan: String = ""
var _fade_selesai: bool = false
var _audio_menunggu: int = 0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	fade_overlay = find_child("FadeOverlay", true, false) as ColorRect
	btn_mulai = find_child("BtnMulai", true, false) as Button
	btn_pengaturan = find_child("BtnPengaturan", true, false) as Button
	btn_kredit = find_child("BtnKredit", true, false) as Button
	btn_keluar = find_child("BtnKeluar", true, false) as Button
	audio_ui = find_child("AudioUI", true, false) as AudioStreamPlayer
	walkie_talkie = find_child("Walkie Talkie", true, false) as Node3D
	judul = find_child("JudulFrekuensi", true, false) as Label
	menu_tombol = get_node_or_null("CanvasLayer/VBoxContainer") as Control
	panel_pengaturan = find_child("PanelPengaturan", true, false)
	panel_kesulitan = find_child("PanelKesulitan", true, false)
	panel_kredit = find_child("PanelKredit", true, false)
	panel_tutorial = find_child("PanelTutorial", true, false)

	if fade_overlay:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_overlay.color.a = 1.0
		var t := create_tween()
		t.tween_property(fade_overlay, "color:a", 0.0, durasi_fade) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if btn_mulai:
		btn_mulai.pressed.connect(_on_mulai_pressed)
	if btn_pengaturan:
		btn_pengaturan.pressed.connect(_on_pengaturan_pressed)
	if btn_kredit:
		btn_kredit.pressed.connect(_on_kredit_pressed)
	if btn_keluar:
		btn_keluar.pressed.connect(_on_keluar_pressed)

	_sambung_panel(panel_pengaturan, "PanelPengaturan")
	_sambung_panel(panel_kesulitan, "PanelKesulitan")
	_sambung_panel(panel_kredit, "PanelKredit")
	_sambung_panel(panel_tutorial, "PanelTutorial")

	if panel_kesulitan and panel_kesulitan.has_signal("konfirmasi"):
		panel_kesulitan.connect("konfirmasi", _on_kesulitan_dikonfirmasi)
	elif panel_kesulitan:
		push_warning("PanelKesulitan tidak punya signal 'konfirmasi'. Cek script yang terpasang.")

	_pasang_tombol_tutorial()

	# Panel tutorial bisa langsung terbuka saat pertama kali main.
	# Kalau begitu, menu harus disembunyikan juga.
	if panel_tutorial and panel_tutorial.get("visible") == true:
		_sembunyikan_menu(true)
		
	if btn_mulai: Pengaturan.daftarkan_teks(btn_mulai, "MENU_MULAI")
	if btn_pengaturan: Pengaturan.daftarkan_teks(btn_pengaturan, "MENU_PENGATURAN")
	if btn_kredit: Pengaturan.daftarkan_teks(btn_kredit, "MENU_KREDIT")
	if btn_keluar: Pengaturan.daftarkan_teks(btn_keluar, "MENU_KELUAR")

	_mulai_backsound()


## Menyambung signal dibuka dan ditutup dengan aman.
## Kalau signal tidak ditemukan, muncul warning dengan nama panelnya.
func _sambung_panel(panel: Node, nama: String) -> void:
	if panel == null:
		push_warning("%s tidak ditemukan di scene" % nama)
		return
	if not panel.has_signal("dibuka") or not panel.has_signal("ditutup"):
		push_warning("%s tidak punya signal 'dibuka' atau 'ditutup'. Cek script yang terpasang." % nama)
		return
	panel.connect("dibuka", _saat_panel_dibuka)
	panel.connect("ditutup", _saat_panel_ditutup)


# --- Tombol tutorial (gambar tanda tanya di kiri atas) ---

func _pasang_tombol_tutorial() -> void:
	if panel_tutorial == null:
		push_warning("PanelTutorial tidak ditemukan di scene")
		return

	if gambar_tombol_tutorial:
		var tb := TextureButton.new()
		tb.texture_normal = gambar_tombol_tutorial
		tb.ignore_texture_size = true
		tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn_tutorial = tb
	else:
		var b := Button.new()
		b.text = "?"
		btn_tutorial = b

	btn_tutorial.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_tutorial.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	btn_tutorial.mouse_entered.connect(_efek_skala_tutorial.bind(1.08))
	btn_tutorial.mouse_exited.connect(_efek_skala_tutorial.bind(1.0))
	btn_tutorial.button_down.connect(_efek_skala_tutorial.bind(0.94))
	btn_tutorial.button_up.connect(_efek_skala_tutorial.bind(1.0))

	# Tombol ditaruh tepat sebelum panel tutorial, supaya panel menutupi tombol saat terbuka
	var wadah: Node = panel_tutorial.get_parent()
	wadah.add_child(btn_tutorial)
	wadah.move_child(btn_tutorial, panel_tutorial.get_index())

	_rapikan_tombol_tutorial()
	get_viewport().size_changed.connect(_rapikan_tombol_tutorial)


func _rapikan_tombol_tutorial() -> void:
	if btn_tutorial == null:
		return
	var v: Vector2 = get_viewport().get_visible_rect().size
	var ukuran: float = clampf(v.y * rasio_tombol_tutorial, 56.0, 128.0)
	var margin: float = clampf(v.y * 0.03, 12.0, 40.0)

	btn_tutorial.offset_left = margin
	btn_tutorial.offset_top = margin
	btn_tutorial.offset_right = margin + ukuran
	btn_tutorial.offset_bottom = margin + ukuran
	btn_tutorial.pivot_offset = Vector2(ukuran, ukuran) * 0.5

	if btn_tutorial is Button:
		(btn_tutorial as Button).add_theme_font_size_override("font_size", roundi(ukuran * 0.5))


func _efek_skala_tutorial(skala: float) -> void:
	if btn_tutorial == null:
		return
	btn_tutorial.pivot_offset = btn_tutorial.size * 0.5
	var t := create_tween()
	t.tween_property(btn_tutorial, "scale", Vector2(skala, skala), 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_btn_tutorial_pressed() -> void:
	mainkan_suara_klik()
	if panel_tutorial and panel_tutorial.has_method("buka"):
		panel_tutorial.call("buka")


# --- Menu saat panel dibuka/ditutup ---

func _saat_panel_dibuka() -> void:
	_sembunyikan_menu(true)

func _saat_panel_ditutup() -> void:
	_sembunyikan_menu(false)

func _sembunyikan_menu(sembunyi: bool) -> void:
	var target := 0.0 if sembunyi else 1.0

	if menu_tombol:
		if not sembunyi:
			menu_tombol.visible = true
		var a := create_tween()
		a.tween_property(menu_tombol, "modulate:a", target, durasi_sembunyi_menu)

	if judul:
		if not sembunyi:
			judul.visible = true
		var b := create_tween()
		b.tween_property(judul, "self_modulate:a", target, durasi_sembunyi_menu)

	var c := create_tween()
	c.tween_interval(durasi_sembunyi_menu)
	c.tween_callback(func():
		if sembunyi:
			if menu_tombol: menu_tombol.visible = false
			if judul: judul.visible = false
	)


# --- Transisi scene ---

func _pindah_scene(path: String) -> void:
	_scene_tujuan = path
	_fade_selesai = false
	_audio_menunggu = 0

	if judul and judul.has_method("animasi_keluar"):
		judul.animasi_keluar()

	if fade_overlay:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var t := create_tween()
		t.tween_property(fade_overlay, "color:a", 1.0, durasi_fade) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_callback(func():
			_fade_selesai = true
			_cek_siap_pindah()
		)
	else:
		_fade_selesai = true

	_tunggu_audio(fade_keluar_backsound())
	_mainkan_transisi()

	_cek_siap_pindah()

func _tunggu_audio(t: Tween) -> void:
	if not t:
		return
	_audio_menunggu += 1
	t.finished.connect(func():
		_audio_menunggu -= 1
		_cek_siap_pindah()
	)

func _cek_siap_pindah() -> void:
	if _scene_tujuan == "" or not _fade_selesai or _audio_menunggu > 0:
		return
	var tujuan := _scene_tujuan
	_scene_tujuan = ""
	get_tree().change_scene_to_file(tujuan)


# --- Suara transisi scene (efek, ikut slider SFX) ---

func _mainkan_transisi() -> void:
	if not suara_transisi:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = suara_transisi
	p.bus = BUS_SFX
	p.volume_db = volume_db_transisi
	p.play()

	var t := create_tween()
	t.tween_interval(transisi_tunda)
	t.tween_property(p, "volume_db", volume_db_senyap, transisi_durasi_fade_keluar) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tunggu_audio(t)


# --- Backsound (musik, ikut slider Musik) ---

func _mulai_backsound() -> void:
	if not backsound:
		print("INFO: Backsound menu belum diisi di Inspector")
		return
	audio_backsound = AudioStreamPlayer.new()
	add_child(audio_backsound)
	audio_backsound.stream = backsound
	audio_backsound.bus = BUS_MUSIK
	audio_backsound.volume_db = volume_db_senyap
	audio_backsound.play()
	fade_masuk_backsound()

func fade_masuk_backsound() -> Tween:
	if not audio_backsound:
		return null
	if _tween_backsound and _tween_backsound.is_valid():
		_tween_backsound.kill()
	_tween_backsound = create_tween()
	_tween_backsound.tween_interval(fade_masuk_tunda)
	_tween_backsound.tween_property(audio_backsound, "volume_db", volume_db_backsound, fade_masuk_durasi) \
		.set_trans(fade_masuk_transisi).set_ease(fade_masuk_easing)
	return _tween_backsound

func fade_keluar_backsound() -> Tween:
	if not audio_backsound:
		return null
	if _tween_backsound and _tween_backsound.is_valid():
		_tween_backsound.kill()
	_tween_backsound = create_tween()
	_tween_backsound.tween_property(audio_backsound, "volume_db", volume_db_senyap, fade_keluar_durasi) \
		.set_trans(fade_keluar_transisi).set_ease(fade_keluar_easing)
	return _tween_backsound


# --- Klik UI (efek, ikut slider SFX) ---

func mainkan_suara_klik() -> void:
	if not suara_klik_tombol:
		print("ERROR: File audio di Inspector 'Suara Klik Tombol' masih kosong/null!")
		return
	if not audio_ui:
		print("ERROR: Node 'AudioUI' tidak ditemukan di scene!")
		return

	audio_ui.stream = suara_klik_tombol
	audio_ui.volume_db = volume_db_tombol
	audio_ui.pitch_scale = 1.0 + randf_range(-variasi_pitch_klik, variasi_pitch_klik)
	audio_ui.bus = BUS_SFX

	if audio_ui.playing:
		audio_ui.stop()

	audio_ui.play()


# --- Tombol ---

func _on_mulai_pressed() -> void:
	mainkan_suara_klik()
	if panel_kesulitan and panel_kesulitan.has_method("buka"):
		panel_kesulitan.call("buka")

func _on_kesulitan_dikonfirmasi(indeks: int) -> void:
	mainkan_suara_klik()
	GameState.kesulitan = indeks
	_nonaktifkan_semua_tombol()

	# Panel kesulitan keluar dan walkie talkie menyala bersamaan
	var t: Tween = null
	if panel_kesulitan and panel_kesulitan.has_method("animasi_keluar"):
		t = panel_kesulitan.call("animasi_keluar") as Tween

	if walkie_talkie and walkie_talkie.has_method("nyalakan_permanen"):
		walkie_talkie.nyalakan_permanen()

	# Tunggu panel selesai keluar, lalu layar menggelap dan scene berganti
	if t:
		await t.finished

	await get_tree().create_timer(jeda_sebelum_mulai).timeout
	_pindah_scene(scene_gameplay)

func _on_pengaturan_pressed() -> void:
	mainkan_suara_klik()
	if panel_pengaturan and panel_pengaturan.has_method("buka"):
		panel_pengaturan.call("buka")

func _on_kredit_pressed() -> void:
	mainkan_suara_klik()
	if panel_kredit and panel_kredit.has_method("buka"):
		panel_kredit.call("buka")

func _on_keluar_pressed() -> void:
	mainkan_suara_klik()
	_nonaktifkan_semua_tombol()
	await get_tree().create_timer(jeda_sebelum_keluar).timeout
	get_tree().quit()

func _nonaktifkan_semua_tombol() -> void:
	if btn_mulai: btn_mulai.disabled = true
	if btn_pengaturan: btn_pengaturan.disabled = true
	if btn_kredit: btn_kredit.disabled = true
	if btn_keluar: btn_keluar.disabled = true
	if btn_tutorial: btn_tutorial.disabled = true

func _aktifkan_semua_tombol() -> void:
	if btn_mulai: btn_mulai.disabled = false
	if btn_pengaturan: btn_pengaturan.disabled = false
	if btn_kredit: btn_kredit.disabled = false
	if btn_keluar: btn_keluar.disabled = false
	if btn_tutorial: btn_tutorial.disabled = false
