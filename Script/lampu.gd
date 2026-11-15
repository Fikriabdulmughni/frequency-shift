extends Node3D

@export var mat_off: StandardMaterial3D
@export var mat_on: StandardMaterial3D
@export var led_mesh: MeshInstance3D

@onready var radio_audio: AudioStreamPlayer3D = $"Walkie Talkie/AudioStreamPlayer"
@onready var click_up: AudioStreamPlayer3D = $"Walkie Talkie/ClickAudioUp"
@onready var click_down: AudioStreamPlayer3D = $"Walkie Talkie/ClickAudioDown"
@onready var anomaly_audio: AudioStreamPlayer3D = $"Walkie Talkie/AnomalyAudioPlayer"
@onready var jangkrik_audio: AudioStreamPlayer = $JangkrikAudio

@export var anim_player: AnimationPlayer
@export var paper_anim_player: AnimationPlayer

@export var heartbeat_audio: AudioStreamPlayer
@export var climax_bell_audio: AudioStreamPlayer

@export var camera_node: Camera3D

@export var skeleton_ik_kanan: SkeletonIK3D
@export var skeleton_ik_kiri: SkeletonIK3D

@onready var label_kertas_catatan: Label = $CanvasLayer/PanelKertasMorse/LabelKertasCatatan
@onready var label_layar_radio: RichTextLabel = $CanvasLayer/LabelLayarRadio
@onready var label_misi_bawah: Label = $CanvasLayer/LabelMisiBawah
@onready var overlay_tutup_mata: ColorRect = $CanvasLayer/OverlayTutupMata
@onready var overlay_anomali_suara: TextureRect = $CanvasLayer/OverlayAnomaliSuara
@onready var overlay_vinyet_visual: ColorRect = $CanvasLayer/OverlayVinyetVisual

@export_category("Pengaturan Fade In Masuk Scene")
@export var durasi_fade_in: float = 1.0

@export_category("Pengaturan Dinamis Tutup Mata")
@export var kecepatan_tutup_mata: float = 15.0
@export var kecepatan_buka_mata: float = 12.0

@export_category("UI Event Ranger")
@export var panel_event_ranger: Control
@export var label_pertanyaan_ranger: Label
@export var btn_pilihan_1: Button
@export var btn_pilihan_2: Button
@export var btn_pilihan_3: Button
@export var btn_pilihan_4: Button
@export var label_timer_event: Label

@export_category("Tombol Sentuh")
## Seret semua tombol sentuh ke sini (radio, mata, panah, morse, pilihan ranger, dll.)
@export var tombol_sentuh: Array[Button] = []

@export_category("Jeda Setelah Event Ranger")
## Minimal detik sebelum anomali berikutnya bisa muncul setelah event ranger selesai
@export var jeda_anomali_setelah_ranger: float = 4.0

@export_category("Arah Suara Anomali")
## Titik di dunia tempat suara anomali bisa muncul. Seret node Marker3D ke sini.
@export var titik_suara_anomali: Array[Node3D] = []
## Dipakai pada mode "Acak Sekitar Kamera": jarak suara dari kamera.
@export var jarak_suara_anomali: float = 8.0
@export_enum("Acak dari Titik", "Acak Sekitar Kamera") var mode_arah_anomali: int = 0

var daftar_arsip_misi: Array[Dictionary] = [
	{ "koordinat": "19.42.805", "target_kalimat": "MY CAR IS NEAR THE CLIFF" },
	{ "koordinat": "45.10.913", "target_kalimat": "I NEED HELP FROM SOMEONE" },
	{ "koordinat": "72.88.304", "target_kalimat": "SOMETHING IS WRONG HERE" },
	{ "koordinat": "31.55.670", "target_kalimat": "WESTWARDS FROM THE POST" },
	{ "koordinat": "88.03.149", "target_kalimat": "SEND ME HELP IMMEDIATELY" },
	{ "koordinat": "12.75.402", "target_kalimat": "IM SCARED SAVE ME RANGER" },
	{ "koordinat": "64.21.983", "target_kalimat": "I CANT MOVE MY WHOLE BODY" },
	{ "koordinat": "99.14.320", "target_kalimat": "COORDINATES HAVE BEEN SENT" },
	{ "koordinat": "23.90.511", "target_kalimat": "HURRY UP SOMETHING IS WEIRD OUT HERE" },
	{ "koordinat": "57.33.688", "target_kalimat": "OH MY GOD HURRY UP SIR" }
]

var daftar_event_ranger: Array[Dictionary] = [
	{
		"teks_ranger": "RANGER: ARE YOU SAFE OVER THERE? [... .- ..-. . ?]",
		"pilihan": [
			{"kode": ".-", "teks": "YES I AM SAFE", "benar": true},
			{"kode": "-...", "teks": "SOMETHING IS HERE", "benar": false},
			{"kode": "--.", "teks": "I HEAR FOOTSTEPS", "benar": false},
			{"kode": "-..", "teks": "HELP ME FAST", "benar": false}
		]
	},
	{
		"teks_ranger": "RANGER: CAN YOU HOLD THE LINE? [-.-. .- -. -.]",
		"pilihan": [
			{"kode": "..", "teks": "YES I CAN", "benar": false},
			{"kode": "---", "teks": "SIGNAL IS LOST", "benar": false},
			{"kode": ".-..", "teks": "HOLDING ON NOW", "benar": true},
			{"kode": "...-", "teks": "I WANT TO ESCAPE", "benar": false}
		]
	},
	{
		"teks_ranger": "RANGER: WHAT DO YOU SEE OUT THERE? [-.. ---]",
		"pilihan": [
			{"kode": ".----", "teks": "NOTHING AT ALL", "benar": false},
			{"kode": "..---", "teks": "A DARK FIGURE", "benar": true},
			{"kode": "...--", "teks": "JUST THE TREES", "benar": false},
			{"kode": "....-", "teks": "MY CAR LIGHTS", "benar": false}
		]
	},
	{
		"teks_ranger": "RANGER: WHERE IS YOUR POSITION NOW? [-.. ..- .]",
		"pilihan": [
			{"kode": "...---...", "teks": "NEAR THE OLD SHACK", "benar": true},
			{"kode": ".-.-.-", "teks": "DEEP IN THE WOODS", "benar": false},
			{"kode": "-..-.", "teks": "BY THE MAIN ROAD", "benar": false},
			{"kode": "..--..", "teks": "LOST IN THE FOG", "benar": false}
		]
	},
	{
		"teks_ranger": "RANGER: DO YOU COPY MY VOICE CLEARLY? (-. -.-.)",
		"pilihan": [
			{"kode": "--.-", "teks": "LOUD AND CLEAR", "benar": false},
			{"kode": "..-.", "teks": "STATIC IS TOO LOUD", "benar": true},
			{"kode": "-.-.", "teks": "VOICE IS MUTED", "benar": false},
			{"kode": "...-.", "teks": "SIGNAL DROPPING", "benar": false}
		]
	}
]

var misi_aktif: Dictionary = {}
var koordinat_target: String = ""
var target_kalimat: String = ""

var tahap_misi: int = 0
var indeks_karakter_aktif: int = 0
var target_morse_karakter_ini: String = ""

var kamus_morse: Dictionary = {
	"A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.",
	"G": "--.", "H": "....", "I": "..", "J": ".---", "K": "-.-", "L": ".-..",
	"M": "--", "N": "-.", "O": "---", "P": ".--.", "Q": "--.-", "R": ".-.",
	"S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
	"Y": "-.--", "Z": "--..",
	"0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
	"5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----."
}

var daftar_halaman_kertas: Array[String] = []
var indeks_halaman_aktif: int = 0

@export_category("Pengaturan Debug & Playtest")
@export var debug_god_mode: bool = false
@export var debug_skip_to_climax: bool = false
@export var debug_anomali_suara: bool = true
@export_enum("Easy (Santai)", "Normal (Standar)", "Hardcore (Tegang)", "Nightmare (Ekstrem)") var game_difficulty: int = 1

@export_category("Pengaturan Audio Anomali")
## Daftar suara anomali. Setiap entri berisi stream, bobot, potong, volume, dan pitch sendiri.
@export var daftar_anomali_suara: Array[EntriAnomaliSuara] = []
## Jeda (detik) yang dikurangkan dari batas reaksi saat memilih suara yang boleh dipakai.
## Suara harus selesai sebelum batas reaksi habis.
@export var kompensasi_suara_anomali: float = 0.3

@export_category("Pengaturan Anomali Visual")
@export var monster_node: Node3D
@export var monster_animation_player: AnimationPlayer
## Nama animasi pose. Pose yang tidak ada di AnimationPlayer akan dilewati dan dicatat di Output.
@export var monster_poses: Array[String] = ["pose_1", "pose_2", "pose_3", "pose_4"]
## Node anomali visual tambahan. Ikut muncul dan hilang bersama monster_node.
@export var monster_node_tambahan: Array[Node3D] = []
## Opsional. Index-nya sejajar dengan monster_node_tambahan. Kosongkan jika node tidak perlu animasi.
@export var monster_animation_player_tambahan: Array[AnimationPlayer] = []

@export_category("Kekalahan Visual")
## Node KekalahanVisual yang memainkan animasi, audio, dan glitch saat kalah visual
@export var kekalahan_visual: KekalahanVisual

@export_category("Kematian Suara")
## Lama kepala menengadah dan bergerak sebelum layar pindah (detik)
@export var durasi_goyang_kamera_suara: float = 1.2
## Seberapa kuat gerakan kepala saat kematian suara. 1.0 normal, lebih besar lebih heboh
@export_range(0.0, 3.0) var intensitas_goyang_kamera_suara: float = 1.0

@export_category("Volume Statis Radio")
## Volume statis saat tepat di frekuensi target (dB). 0 = paling keras.
@export_range(-40.0, 6.0) var volume_statis_dekat_db: float = 0.0
## Volume statis saat jauh dari frekuensi target (dB). Makin kecil makin senyap.
@export_range(-80.0, 0.0) var volume_statis_jauh_db: float = -40.0
## Jarak frekuensi (MHz) saat statis sudah di volume paling pelan
@export var jarak_maks_statis: float = 20.0

var visual_anomaly_timer: float = 0.0
var next_visual_anomaly_time: float = 20.0
var is_visual_anomaly_active: bool = false
var visual_reaction_timer: float = 0.0
var max_visual_reaction_time: float = 3.0

var eye_closure_timer: float = 0.0
var required_eye_closure_time: float = 2.0

var camera_shake_duration: float = 0.0
var camera_shake_intensity: float = 0.0
var default_camera_fov: float = 75.0

enum State { SEARCHING, TRANSMITTING, CLIMAX_SURVIVE }
var current_state: State = State.SEARCHING

var current_frequency: float = 10.0
var target_frequency: float = 50.0
var min_frequency: float = 10.0
var max_frequency: float = 100.0
var is_in_range: bool = false

var signal_hold_timer: float = 0.0
var required_hold_time: float = 3.0

var morse_progress: String = ""

var disconnection_timer: float = 0.0
var next_disconnection_time: float = 6.0

var climax_timer: float = 0.0
var max_climax_time: float = 40.0

var is_ranger_event_active: bool = false
var has_triggered_ranger_event: bool = false
var event_timer: float = 0.0
var max_event_time: float = 8.0
var current_event_data: Dictionary = {}

var is_holding_radio: bool = false
var is_eyes_closed: bool = false
var is_paper_out: bool = false

var is_virtual_up_pressed: bool = false
var is_virtual_down_pressed: bool = false
var is_virtual_morse_holding: bool = false
var virtual_morse_press_time: float = 0.0

var anomaly_timer: float = 0.0
var next_anomaly_time: float = 15.0
var is_sound_anomaly_active: bool = false
var sound_reaction_timer: float = 0.0
var max_sound_reaction_time: float = 3.0

# Suara anomali yang lolos filter (durasi cukup untuk batas reaksi saat ini)
var _pilihan_suara: Array[EntriAnomaliSuara] = []
# Titik detik saat suara dipotong. 0 berarti tidak dipotong dan diputar sampai habis.
var _batas_potong_suara: float = 0.0
var _sedang_potong: bool = false
var _timer_log_suara: float = 0.0

# Pose yang sudah pernah diperingatkan, supaya peringatan tidak berulang tiap anomali
var _pose_sudah_diperingatkan: Dictionary = {}

const PATH_KEMATIAN := "res://scene_kematian.tscn"
var sedang_mati: bool = false

# Posisi dan visibilitas awal node anomali tambahan, disimpan saat _ready
var _transform_awal_tambahan: Array[Transform3D] = []
var _visible_awal_tambahan: Array[bool] = []

# Lapisan fade masuk untuk scene baru
var lapisan_fade_masuk: ColorRect

func _ready() -> void:
	# Ambil tingkat kesulitan yang dipilih di menu utama
	game_difficulty = GameState.kesulitan
	_pasang_bus_sfx()
	# Tunggu satu frame supaya ukuran tombol sudah dihitung, lalu terapkan
	_terapkan_ukuran_tombol_sentuh.call_deferred()
	Pengaturan.berubah.connect(_saat_pengaturan_berubah)

	if skeleton_ik_kanan and not skeleton_ik_kanan.is_running(): skeleton_ik_kanan.start()
	if skeleton_ik_kiri and not skeleton_ik_kiri.is_running(): skeleton_ik_kiri.start()

	if camera_node: default_camera_fov = camera_node.fov

	# Buat efek Fade In dari hitam saat scene mulai
	_buat_lapisan_fade_masuk()

	# Lepaskan suara anomali dari Walkie Talkie agar posisinya tetap di dunia, tidak ikut tangan
	if anomaly_audio and anomaly_audio.get_parent() != self:
		anomaly_audio.reparent(self, true)

	misi_aktif = daftar_arsip_misi[randi() % daftar_arsip_misi.size()]
	koordinat_target = misi_aktif["koordinat"]
	target_kalimat = misi_aktif["target_kalimat"]

	tahap_misi = 0
	indeks_karakter_aktif = 0
	perbarui_target_karakter_morse()

	target_frequency = snappedf(randf_range(min_frequency, max_frequency) * 2.0, 1.0) / 2.0

	inisialisasi_halaman_kertas()
	perbarui_tampilan_kertas()
	update_led_state(false)

	if label_misi_bawah: label_misi_bawah.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if panel_event_ranger: panel_event_ranger.visible = false
	if overlay_tutup_mata: overlay_tutup_mata.modulate.a = 0.0
	if overlay_anomali_suara: overlay_anomali_suara.modulate.a = 0.0
	if overlay_vinyet_visual:
		overlay_vinyet_visual.modulate.a = 0.0
		if overlay_vinyet_visual.material is ShaderMaterial:
			overlay_vinyet_visual.material.set_shader_parameter("radius", 1.8)
	if monster_node: monster_node.visible = false
	_simpan_kondisi_awal_tambahan()

	if radio_audio:
		if not radio_audio.finished.is_connected(_on_audio_finished): radio_audio.finished.connect(_on_audio_finished)
		radio_audio.volume_db = -80.0
		radio_audio.playing = true

	if jangkrik_audio:
		jangkrik_audio.volume_db = -5.0
		jangkrik_audio.play()

	atur_parameter_kesulitan_awal()
	_siapkan_anomali_suara()
	if debug_skip_to_climax: trigger_klimaks_misi()

func _buat_lapisan_fade_masuk() -> void:
	var canvas := get_node_or_null("CanvasLayer")
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.layer = 128
		add_child(canvas)

	lapisan_fade_masuk = ColorRect.new()
	lapisan_fade_masuk.color = Color.BLACK
	lapisan_fade_masuk.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan_fade_masuk.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(lapisan_fade_masuk)

	var t := create_tween()
	t.tween_property(lapisan_fade_masuk, "color:a", 0.0, durasi_fade_in)
	t.tween_callback(lapisan_fade_masuk.queue_free)

func atur_parameter_kesulitan_awal() -> void:
	var diff_multiplier = [1.5, 1.0, 0.7, 0.4][game_difficulty]
	next_anomaly_time = randf_range(15.0, 25.0) * diff_multiplier
	next_visual_anomaly_time = randf_range(20.0, 35.0) * diff_multiplier
	max_sound_reaction_time = 3.0 * diff_multiplier
	max_visual_reaction_time = 3.0 * diff_multiplier

func _on_audio_finished() -> void:
	if radio_audio: radio_audio.play()

## Membaca nilai pengaturan. Jika belum ada, pakai nilai cadangan.
func _pengaturan_float(kunci: String, cadangan: float) -> float:
	var v: Variant = Pengaturan.get_nilai(kunci)
	return float(v) if v != null else cadangan

## Getar HP hanya jika opsi Getar Layar (Haptic) aktif di pengaturan
func _getar(ms: int) -> void:
	if _pengaturan_float("getar_haptic", 0.0) > 0.5:
		Input.vibrate_handheld(ms)

## Membesarkan atau mengecilkan tombol sentuh sesuai pengaturan "Ukuran Tombol Sentuh"
func _terapkan_ukuran_tombol_sentuh() -> void:
	var pengali: float = clampf(_pengaturan_float("ukuran_tombol", 1.0), 0.7, 1.5)
	for b: Button in tombol_sentuh:
		if b == null:
			continue
		b.pivot_offset = b.size * 0.5
		b.scale = Vector2(pengali, pengali)

## Dipanggil saat pengaturan berubah, supaya ukuran langsung ikut berubah
func _saat_pengaturan_berubah(kunci: String) -> void:
	if kunci == "ukuran_tombol":
		_terapkan_ukuran_tombol_sentuh()
	elif kunci == "bahasa" or kunci == "semua":
		inisialisasi_halaman_kertas()
		perbarui_tampilan_kertas()

# Fade berbasis Tween. Dipakai untuk suara sekali-pakai (anomali), bukan untuk radio yang berubah tiap frame
func fade_audio(player, target_db: float, duration: float) -> void:
	if not player: return
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "volume_db", target_db, duration)

# Volume radio didekatkan ke target setiap frame tanpa membuat Tween baru
func _atur_volume_radio(target_db: float, durasi: float, delta: float) -> void:
	if not radio_audio: return
	var kecepatan := 80.0 / maxf(durasi, 0.01)
	radio_audio.volume_db = move_toward(radio_audio.volume_db, target_db, kecepatan * delta)

func perbarui_target_karakter_morse() -> void:
	if tahap_misi == 0:
		while indeks_karakter_aktif < koordinat_target.length():
			if koordinat_target.substr(indeks_karakter_aktif, 1) == ".":
				indeks_karakter_aktif += 1
			else:
				target_morse_karakter_ini = kamus_morse.get(koordinat_target.substr(indeks_karakter_aktif, 1), "")
				return
		tahap_misi = 1
		indeks_karakter_aktif = 0
		perbarui_target_karakter_morse()
	elif tahap_misi == 1:
		while indeks_karakter_aktif < target_kalimat.length():
			if target_kalimat.substr(indeks_karakter_aktif, 1) == " ":
				indeks_karakter_aktif += 1
			else:
				target_morse_karakter_ini = kamus_morse.get(target_kalimat.substr(indeks_karakter_aktif, 1), "")
				return
		trigger_klimaks_misi()

func trigger_klimaks_misi() -> void:
	current_state = State.CLIMAX_SURVIVE
	climax_timer = 0.0
	has_triggered_ranger_event = false

	var climax_mult = [1.2, 1.0, 0.7, 0.5][game_difficulty]
	next_anomaly_time = 3.0 * climax_mult
	next_visual_anomaly_time = 5.0 * climax_mult

	if climax_bell_audio:
		climax_bell_audio.volume_db = 0.0
		climax_bell_audio.play()

func inisialisasi_halaman_kertas() -> void:
	daftar_halaman_kertas = [
		tr("KERTAS_FREQ_TARGET") + ": " + str(target_frequency) + " " + tr("KERTAS_MHZ") + "\n\n" + tr("KERTAS_NUMBERS") + "\n1: .----   6: -....\n2: ..---   7: --...\n3: ...--   8: ---..\n4: ....-   9: ----.\n5: .....   0: -----",
		tr("KERTAS_ALPHABET_AM") + "\n\nA: .-     H: ....\nB: -...   I: ..\nC: -.-.   J: .---\nD: -..    K: -.-\nE: .      L: .-..\nF: ..-.   M: --\nG: --.",
		tr("KERTAS_ALPHABET_NZ") + "\n\nN: -.     U: ..-\nO: ---    V: ...-\nP: .--.   W: .--\nQ: --.-   X: -..-\nR: .-.    Y: -.--\nS: ...    Z: --..\nT: -"
	]

func perbarui_tampilan_kertas() -> void:
	if label_kertas_catatan and not daftar_halaman_kertas.is_empty():
		label_kertas_catatan.text = daftar_halaman_kertas[indeks_halaman_aktif]

func _process(delta: float) -> void:
	if not is_ranger_event_active:
		handle_sound_anomaly_system(delta)
		handle_visual_anomaly_system(delta)
	else:
		handle_ranger_event_logic(delta)

	if is_virtual_morse_holding: virtual_morse_press_time += delta

	# Camera Shake yang Halus
	if camera_node:
		var time = Time.get_ticks_msec() * 0.01
		var current_shake = camera_shake_intensity * (camera_shake_duration / 0.8) if camera_shake_duration > 0.0 else 0.0
		var sway_x = sin(time * 3.5) * 0.0008 + randf_range(-current_shake, current_shake)
		var sway_y = cos(time * 4.0) * 0.0008 + randf_range(-current_shake, current_shake)

		if camera_shake_duration > 0.0: camera_shake_duration -= delta
		else: camera_shake_intensity = 0.0

		camera_node.h_offset = sway_x
		camera_node.v_offset = sway_y

	# UI Overlays & Labels
	if overlay_tutup_mata:
		overlay_tutup_mata.modulate.a = move_toward(overlay_tutup_mata.modulate.a, float(is_eyes_closed), delta * (kecepatan_tutup_mata if is_eyes_closed else kecepatan_buka_mata))

	# Efek Merah Berdenyut Organik saat Anomali Suara
	if overlay_anomali_suara:
		var pulse = abs(sin(Time.get_ticks_msec() * 0.01)) * 0.35 + 0.1
		var target_alpha = pulse if is_sound_anomaly_active else 0.0
		overlay_anomali_suara.modulate.a = move_toward(overlay_anomali_suara.modulate.a, target_alpha, delta * 8.0)

	# Animasi Vignet Menyebar (Fade In / Fade Out & Radius Lebar)
	if overlay_vinyet_visual:
		var target_vignette_alpha = 0.55 if is_visual_anomaly_active else 0.0
		overlay_vinyet_visual.modulate.a = move_toward(overlay_vinyet_visual.modulate.a, target_vignette_alpha, delta * 4.0)

		if overlay_vinyet_visual.material is ShaderMaterial:
			var target_radius = 1.0 if is_visual_anomaly_active else 1.8
			var current_radius = overlay_vinyet_visual.material.get_shader_parameter("radius")
			if current_radius != null:
				var new_radius = move_toward(current_radius, target_radius, delta * 2.5)
				overlay_vinyet_visual.material.set_shader_parameter("radius", new_radius)

	if camera_node:
		var target_fov = (default_camera_fov - 5.0) if is_visual_anomaly_active else default_camera_fov
		camera_node.fov = move_toward(camera_node.fov, target_fov, delta * 15.0)

	if label_layar_radio:
		if not is_holding_radio: label_layar_radio.text = "STORED"
		elif current_state == State.TRANSMITTING: label_layar_radio.text = "Morse: " + morse_progress + " "
		elif current_state == State.CLIMAX_SURVIVE:
			label_layar_radio.text = "[color=red]HOLD YOUR WALKIE TALKIE![/color]" if not is_holding_radio else "SURVIVE: [color=red]" + str(snappedf(max(0.0, max_climax_time - climax_timer), 0.1)) + "s[/color]"
		else: label_layar_radio.text = "FREQ: " + str(snappedf(current_frequency, 0.1)) + " MHz"

	# Progres titik-titik pada teks misi bawah
	if label_misi_bawah and not misi_aktif.is_empty():
		var koord_tampilan = ""
		for i in range(koordinat_target.length()):
			var c = koordinat_target.substr(i, 1)
			if c == ".": koord_tampilan += "."
			elif tahap_misi > 0 or i < indeks_karakter_aktif: koord_tampilan += "."
			else: koord_tampilan += c

		var pesan_tampilan = ""
		if tahap_misi == 1:
			for i in range(target_kalimat.length()):
				var c = target_kalimat.substr(i, 1)
				if c == " ": pesan_tampilan += " "
				elif i < indeks_karakter_aktif: pesan_tampilan += "."
				else: pesan_tampilan += c
		else:
			pesan_tampilan = target_kalimat

		label_misi_bawah.text = koord_tampilan + "\n" + pesan_tampilan

	# Audio Volume Control Radio: statis makin keras saat dekat frekuensi target
	if radio_audio:
		var should_play_radio = is_holding_radio and not is_eyes_closed
		if not should_play_radio:
			_atur_volume_radio(-80.0, 0.3, delta)
			if not is_holding_radio and is_sound_anomaly_active:
				resolve_sound_anomaly("radio dilepas")
		else:
			_atur_volume_radio(_hitung_volume_statis(), 0.1, delta)

	if is_holding_radio:
		if current_state == State.SEARCHING: handle_frequency_search(delta)
		elif current_state == State.TRANSMITTING: handle_morse_input(delta)
		elif current_state == State.CLIMAX_SURVIVE: handle_climax_survive(delta)


func trigger_camera_shake(duration: float, intensity: float) -> void:
	var pengali: float = _pengaturan_float("getaran_kamera", 1.0)
	camera_shake_duration = duration
	camera_shake_intensity = intensity * pengali

func trigger_ranger_event() -> void:
	# Suara anomali yang sedang berbunyi dihentikan dulu, supaya tidak jalan saat logika ranger berhenti
	if is_sound_anomaly_active:
		resolve_sound_anomaly("event ranger")

	is_ranger_event_active = true
	has_triggered_ranger_event = true
	event_timer = 0.0
	max_event_time = [12.0, 8.0, 6.0, 4.0][game_difficulty]
	current_event_data = daftar_event_ranger[randi() % daftar_event_ranger.size()]

	if panel_event_ranger: panel_event_ranger.visible = true
	if label_pertanyaan_ranger: label_pertanyaan_ranger.text = current_event_data["teks_ranger"]

	for i in range(4):
		var btn = [btn_pilihan_1, btn_pilihan_2, btn_pilihan_3, btn_pilihan_4][i]
		if btn: btn.text = current_event_data["pilihan"][i]["kode"] + "  " + current_event_data["pilihan"][i]["teks"]

func handle_ranger_event_logic(delta: float) -> void:
	event_timer += delta
	if label_timer_event: label_timer_event.text = "TIME: " + str(snappedf(max(0.0, max_event_time - event_timer), 0.1)) + "s"
	if event_timer >= max_event_time:
		if debug_god_mode: selesaikan_ranger_event(true)
		else: trigger_game_over(GameState.RANGER)

func eksekusi_jawaban(indeks: int) -> void:
	if is_ranger_event_active: selesaikan_ranger_event(current_event_data["pilihan"][indeks]["benar"])

func selesaikan_ranger_event(is_correct: bool) -> void:
	is_ranger_event_active = false
	if panel_event_ranger: panel_event_ranger.visible = false
	if not is_correct:
		climax_timer = maxf(0.0, climax_timer - [5.0, 10.0, 15.0, 25.0][game_difficulty])

	visual_anomaly_timer = minf(visual_anomaly_timer, next_visual_anomaly_time - jeda_anomali_setelah_ranger)
	anomaly_timer = minf(anomaly_timer, next_anomaly_time - jeda_anomali_setelah_ranger)

func handle_climax_survive(delta: float) -> void:
	if not is_ranger_event_active and is_holding_radio:
		climax_timer += delta
		if climax_timer >= (max_climax_time * 0.5) and not has_triggered_ranger_event: trigger_ranger_event()
		if climax_timer >= max_climax_time: trigger_victory()

func toggle_radio_state() -> void:
	if anim_player and anim_player.is_playing(): return
	is_holding_radio = not is_holding_radio
	if anim_player:
		if is_holding_radio: anim_player.play("gerak_radio")
		else: anim_player.play_backwards("gerak_radio")
	if is_holding_radio and click_up: click_up.play()
	elif not is_holding_radio and click_down: click_down.play()

func toggle_paper_state() -> void:
	if paper_anim_player and paper_anim_player.is_playing(): return
	is_paper_out = not is_paper_out
	if paper_anim_player:
		if is_paper_out: paper_anim_player.play("gerak_kertas")
		else: paper_anim_player.play_backwards("gerak_kertas")

func _on_panel_kertas_morse_gui_input(_event: InputEvent) -> void:
	if (_event is InputEventMouseButton or _event is InputEventScreenTouch) and _event.pressed:
		toggle_paper_state()

func fade_heartbeat(target_db: float, duration: float) -> void:
	if not heartbeat_audio: return
	if target_db > -80.0 and not heartbeat_audio.playing:
		heartbeat_audio.volume_db = -80.0
		heartbeat_audio.play()
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(heartbeat_audio, "volume_db", target_db, duration)
	if target_db <= -79.0: tween.tween_callback(heartbeat_audio.stop)

# ---------------------------------------------------------------
# Anomali suara: pilihan suara, pemotongan, dan penyelesaian
# ---------------------------------------------------------------

## Menyaring daftar suara. Hanya suara yang selesai sebelum batas reaksi (dikurangi kompensasi) yang dipakai.
## Kalau tidak ada yang cukup pendek, dipakai suara paling pendek sebagai cadangan.
func _siapkan_anomali_suara() -> void:
	_pilihan_suara.clear()
	var batas: float = max_sound_reaction_time - kompensasi_suara_anomali
	var terpendek: EntriAnomaliSuara = null

	for e: EntriAnomaliSuara in daftar_anomali_suara:
		if not _bisa_dipakai(e):
			continue
		if terpendek == null or e.durasi_efektif() < terpendek.durasi_efektif():
			terpendek = e
		if e.durasi_efektif() <= batas:
			_pilihan_suara.append(e)

	if _pilihan_suara.is_empty() and terpendek != null:
		push_warning("Tidak ada suara anomali yang cukup pendek. Memakai yang paling pendek: " + _nama_stream(terpendek))
		_pilihan_suara.append(terpendek)

	if debug_anomali_suara:
		print("[SUARA] SIAP | batas reaksi=%.2f | batas dipakai=%.2f | suara lolos=%d dari %d" % [max_sound_reaction_time, batas, _pilihan_suara.size(), daftar_anomali_suara.size()])
		for e: EntriAnomaliSuara in _pilihan_suara:
			print("[SUARA]   - %s | durasi efektif=%.2f | bobot=%.1f" % [_nama_stream(e), e.durasi_efektif(), e.bobot])

func _bisa_dipakai(e: EntriAnomaliSuara) -> bool:
	if e == null or e.stream == null:
		return false
	if e.bobot <= 0.0:
		return false
	# Suara yang diulang tanpa dipotong tidak akan pernah selesai
	if e.loop_aktif() and e.potong_di_detik <= 0.0:
		return false
	return e.durasi_efektif() > 0.0

## Pemilihan acak berbobot dari suara yang lolos filter
func _pilih_anomali_suara() -> EntriAnomaliSuara:
	if _pilihan_suara.is_empty():
		return null
	var total: float = 0.0
	for e: EntriAnomaliSuara in _pilihan_suara:
		total += e.bobot
	var r: float = randf() * total
	for e: EntriAnomaliSuara in _pilihan_suara:
		r -= e.bobot
		if r <= 0.0:
			return e
	return _pilihan_suara.back()

func handle_sound_anomaly_system(delta: float) -> void:
	if not is_sound_anomaly_active:
		anomaly_timer += delta
		# Anomali hanya muncul saat radio sedang dipegang dan tidak ada suara yang sedang berbunyi
		if anomaly_timer >= next_anomaly_time and is_holding_radio and anomaly_audio and not anomaly_audio.playing:
			trigger_sound_anomaly()
	else:
		sound_reaction_timer += delta
		_cek_potong_suara()

		if debug_anomali_suara:
			_timer_log_suara += delta
			if _timer_log_suara >= 0.5:
				_timer_log_suara = 0.0
				print("[SUARA] AKTIF | reaksi=%.2f/%.2f | pegang=%s | %s" % [sound_reaction_timer, max_sound_reaction_time, is_holding_radio, _status_audio_anomali()])

		if sound_reaction_timer >= max_sound_reaction_time:
			if debug_god_mode: resolve_sound_anomaly("god mode")
			elif is_holding_radio: trigger_game_over(GameState.SUARA)

func trigger_sound_anomaly() -> void:
	if _pilihan_suara.is_empty() or anomaly_audio == null:
		if debug_anomali_suara:
			print("[SUARA] GAGAL MUNCUL | tidak ada suara yang lolos filter")
		return

	var entri: EntriAnomaliSuara = _pilih_anomali_suara()
	if entri == null:
		return

	_getar(120)
	is_sound_anomaly_active = true
	sound_reaction_timer = 0.0
	_timer_log_suara = 0.0
	trigger_camera_shake(0.3, 0.005)

	atur_posisi_suara_anomali()
	anomaly_audio.stream = entri.stream
	anomaly_audio.pitch_scale = entri.pitch
	anomaly_audio.volume_db = -80.0
	anomaly_audio.play()
	fade_audio(anomaly_audio, entri.volume_db, 0.2)

	_batas_potong_suara = entri.potong_di_detik
	print("--- PERINGATAN: ANOMALI SUARA MUNCUL! ---")
	if debug_anomali_suara:
		print("[SUARA] MUNCUL | %s | durasi efektif=%.2f | potong=%.2f | pitch=%.2f | volume=%.1f" % [_nama_stream(entri), entri.durasi_efektif(), _batas_potong_suara, entri.pitch, entri.volume_db])

## Memotong suara saat titik potong tercapai. Pemotongan selesai menyelesaikan anomali (pemain aman).
func _cek_potong_suara() -> void:
	if _sedang_potong or _batas_potong_suara <= 0.0:
		return
	if anomaly_audio == null or not anomaly_audio.playing:
		return
	if anomaly_audio.get_playback_position() >= _batas_potong_suara:
		_potong_suara_anomali()

func _potong_suara_anomali() -> void:
	if _sedang_potong:
		return
	_sedang_potong = true
	var t := create_tween()
	t.tween_property(anomaly_audio, "volume_db", -80.0, 0.15)
	t.tween_callback(func():
		_sedang_potong = false
		if not is_sound_anomaly_active:
			return
		if anomaly_audio:
			anomaly_audio.stop()
		resolve_sound_anomaly("dipotong")
	)

## Mengakhiri anomali suara. Suara yang masih berbunyi difade lalu dihentikan.
func resolve_sound_anomaly(alasan: String = "") -> void:
	var sedang_aktif: bool = is_sound_anomaly_active
	is_sound_anomaly_active = false
	anomaly_timer = 0.0
	sound_reaction_timer = 0.0
	_batas_potong_suara = 0.0

	if anomaly_audio and anomaly_audio.playing:
		var t := create_tween()
		t.tween_property(anomaly_audio, "volume_db", -80.0, 0.2)
		t.tween_callback(anomaly_audio.stop)

	if debug_anomali_suara and sedang_aktif:
		print("[SUARA] SELESAI | alasan=%s | reaksi=%.2f | %s" % [alasan if alasan != "" else "-", sound_reaction_timer, _status_audio_anomali()])

	var ranges = [[3.0, 5.0], [2.0, 4.0], [1.5, 3.0], [0.8, 1.8]] if current_state == State.CLIMAX_SURVIVE else [[20.0, 35.0], [15.0, 25.0], [10.0, 18.0], [5.0, 10.0]]
	next_anomaly_time = randf_range(ranges[game_difficulty][0], ranges[game_difficulty][1])

func _nama_stream(e: EntriAnomaliSuara) -> String:
	if e == null or e.stream == null:
		return "(kosong)"
	if e.stream.resource_path != "":
		return e.stream.resource_path.get_file()
	return "(stream tanpa nama)"

func _status_audio_anomali() -> String:
	if anomaly_audio == null:
		return "audio=null"
	return "playing=%s pos=%.2f vol=%.1f" % [anomaly_audio.playing, anomaly_audio.get_playback_position(), anomaly_audio.volume_db]

func handle_visual_anomaly_system(delta: float) -> void:
	if not is_visual_anomaly_active:
		visual_anomaly_timer += delta
		if visual_anomaly_timer >= next_visual_anomaly_time: trigger_visual_anomaly()
	else:
		visual_reaction_timer += delta
		if is_eyes_closed:
			eye_closure_timer += delta
			if eye_closure_timer >= required_eye_closure_time: resolve_visual_anomaly()
		else:
			eye_closure_timer = 0.0
			if visual_reaction_timer >= max_visual_reaction_time:
				if debug_god_mode: resolve_visual_anomaly()
				else: trigger_game_over(GameState.VISUAL)

func trigger_visual_anomaly() -> void:
	_getar(200)
	is_visual_anomaly_active = true
	visual_reaction_timer = 0.0
	eye_closure_timer = 0.0
	trigger_camera_shake(0.5, 0.008)
	fade_heartbeat(0.0, 0.8)

	if monster_node and monster_animation_player:
		var pose_siap := _pose_tersedia(monster_animation_player)
		if not pose_siap.is_empty():
			monster_animation_player.stop()
			monster_node.visible = true
			monster_animation_player.play(pose_siap[randi() % pose_siap.size()], -1.0, 1.0, false)
			monster_animation_player.seek(0.0, true)

	_atur_monster_tambahan(true)

func resolve_visual_anomaly() -> void:
	is_visual_anomaly_active = false
	visual_anomaly_timer = 0.0
	visual_reaction_timer = 0.0
	eye_closure_timer = 0.0
	fade_heartbeat(-80.0, 0.5)

	var ranges = [[4.0, 6.0], [3.0, 5.0], [2.0, 4.0], [1.2, 2.5]] if current_state == State.CLIMAX_SURVIVE else [[30.0, 45.0], [20.0, 35.0], [15.0, 25.0], [8.0, 14.0]]
	next_visual_anomaly_time = randf_range(ranges[game_difficulty][0], ranges[game_difficulty][1])
	if monster_node: monster_node.visible = false
	_atur_monster_tambahan(false)

## Mengembalikan daftar pose yang benar-benar ada di AnimationPlayer.
## Pose yang tidak ada dilewati, dan peringatannya hanya dicatat sekali.
func _pose_tersedia(anim: AnimationPlayer) -> Array[String]:
	var hasil: Array[String] = []
	if anim == null:
		return hasil
	for p: String in monster_poses:
		if anim.has_animation(p):
			hasil.append(p)
		elif not _pose_sudah_diperingatkan.has(p):
			_pose_sudah_diperingatkan[p] = true
			push_warning("Pose '%s' tidak ada di AnimationPlayer '%s'. Pose ini dilewati." % [p, anim.name])
	return hasil

## Menyimpan posisi dan visibilitas awal setiap node tambahan, sebelum AnimationPlayer menggerakkannya.
func _simpan_kondisi_awal_tambahan() -> void:
	_transform_awal_tambahan.clear()
	_visible_awal_tambahan.clear()
	for node in monster_node_tambahan:
		_transform_awal_tambahan.append(node.transform if node else Transform3D.IDENTITY)
		_visible_awal_tambahan.append(node.visible if node else false)

## Tampil: node tambahan dimunculkan. Jika punya AnimationPlayer sendiri (bukan milik monster), pose acak dimainkan.
## Selesai: AnimationPlayer sendiri dihentikan, lalu node dikembalikan ke posisi dan visibilitas awal.
## Anomali visual (monster_node) tidak disentuh di sini.
func _atur_monster_tambahan(tampil: bool) -> void:
	for i in monster_node_tambahan.size():
		var node: Node3D = monster_node_tambahan[i]
		if not node:
			continue

		var anim: AnimationPlayer = null
		if i < monster_animation_player_tambahan.size():
			anim = monster_animation_player_tambahan[i]
		# Hanya AnimationPlayer yang benar-benar terpisah dari monster yang dikontrol di sini
		var anim_terpisah: bool = anim != null and anim != monster_animation_player

		if tampil:
			node.visible = true
			if anim_terpisah:
				var pose_siap := _pose_tersedia(anim)
				if not pose_siap.is_empty():
					anim.stop()
					anim.play(pose_siap[randi() % pose_siap.size()], -1.0, 1.0, false)
					anim.seek(0.0, true)
		else:
			if anim_terpisah:
				anim.stop()
				anim.seek(0.0, true)
			if i < _transform_awal_tambahan.size():
				node.transform = _transform_awal_tambahan[i]
				node.visible = _visible_awal_tambahan[i]

# Dipanggil saat pemain kalah. Jenis: GameState.VISUAL, GameState.SUARA, atau GameState.RANGER
func trigger_game_over(jenis: int) -> void:
	if sedang_mati: return
	sedang_mati = true
	_getar(400)
	print("GAME OVER jenis: ", jenis)
	fade_heartbeat(-80.0, 0.2)
	_hentikan_audio_gameplay(0.3)

	GameState.jenis = jenis
	set_process(false)

	# Sembunyikan UI gameplay agar tidak ikut tertangkap di gambar
	var ui := get_node_or_null("CanvasLayer")
	if ui:
		ui.visible = false

	if jenis == GameState.VISUAL and kekalahan_visual:
		kekalahan_visual.mulai()
		await kekalahan_visual.selesai
		_ambil_gambar_lalu_pindah()

	elif jenis == GameState.SUARA and camera_node:
		await _kematian_suara_kamera()
		_ambil_gambar_lalu_pindah()

	else:
		_ambil_gambar_lalu_pindah()

func _kematian_suara_kamera() -> void:
	var x_awal: float = camera_node.rotation_degrees.x
	var z_awal: float = camera_node.rotation_degrees.z
	var x_akhir: float = x_awal + 28.5
	var z_akhir: float = z_awal + 4.0

	var t := create_tween()
	t.tween_property(camera_node, "rotation_degrees:x", x_awal + 2.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera_node, "rotation_degrees:x", x_awal + 28.0, 1.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(camera_node, "rotation_degrees:z", z_akhir, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera_node, "rotation_degrees:x", x_akhir, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished

	await _goyang_kamera_suara(x_akhir, z_akhir, durasi_goyang_kamera_suara)

func _goyang_kamera_suara(base_x: float, base_z: float, durasi: float) -> void:
	var base_y: float = camera_node.rotation_degrees.y
	var k: float = intensitas_goyang_kamera_suara * _pengaturan_float("getaran_kamera", 1.0)
	var waktu := 0.0

	var target := Vector3.ZERO
	var timer_pilih := 0.0
	var timer_gemetar := randf_range(0.8, 1.6)
	var sisa_gemetar := 0.0

	var posisi := Vector3.ZERO

	while waktu < durasi and is_instance_valid(camera_node) and is_inside_tree():
		var dt := get_process_delta_time()
		waktu += dt

		timer_pilih -= dt
		if timer_pilih <= 0.0:
			timer_pilih = randf_range(0.25, 0.6)
			target = Vector3(
				randf_range(-1.2, 1.2) * k,
				randf_range(-4.0, 4.0) * k,
				randf_range(-2.0, 2.0) * k
			)

		timer_gemetar -= dt
		if timer_gemetar <= 0.0 and sisa_gemetar <= 0.0:
			sisa_gemetar = 0.25
			timer_gemetar = randf_range(0.8, 1.6)

		var gemetar := 0.0
		if sisa_gemetar > 0.0:
			sisa_gemetar -= dt
			gemetar = sin(waktu * 55.0) * 1.6 * k

		posisi.x = lerpf(posisi.x, target.x, dt * 3.0)
		posisi.y = lerpf(posisi.y, target.y, dt * 2.0)
		posisi.z = lerpf(posisi.z, target.z, dt * 3.0)

		camera_node.rotation_degrees = Vector3(
			base_x + posisi.x + gemetar,
			base_y + posisi.y + gemetar * 0.5,
			base_z + posisi.z
		)
		await get_tree().process_frame

func _ambil_gambar_lalu_pindah() -> void:
	await RenderingServer.frame_post_draw
	var gambar := get_viewport().get_texture().get_image()
	GameState.gambar_terakhir = ImageTexture.create_from_image(gambar)
	get_tree().change_scene_to_file(PATH_KEMATIAN)

func trigger_victory() -> void:
	fade_heartbeat(-80.0, 1.0)
	get_tree().change_scene_to_file("res://cutscene_ending.scn")

func handle_frequency_search(delta: float) -> void:
	if not is_holding_radio or is_eyes_closed:
		is_virtual_up_pressed = false
		is_virtual_down_pressed = false
		return

	var kecepatan_tuning: float = _pengaturan_float("kecepatan_tuning", 1.0)

	if is_virtual_up_pressed:
		current_frequency += 10.0 * kecepatan_tuning * delta
		if click_up and not click_up.playing: click_up.play()
	if is_virtual_down_pressed:
		current_frequency -= 10.0 * kecepatan_tuning * delta
		if click_down and not click_down.playing: click_down.play()

	current_frequency = clampf(current_frequency, min_frequency, max_frequency)
	if abs(current_frequency - target_frequency) <= 0.3:
		if not is_in_range: is_in_range = true
		signal_hold_timer += delta
		update_led_state(true)
		if signal_hold_timer >= required_hold_time:
			current_state = State.TRANSMITTING
			disconnection_timer = 0.0
			next_disconnection_time = [12.0, 6.0, 4.0, 2.5][game_difficulty]
	else:
		if is_in_range:
			is_in_range = false
			signal_hold_timer = 0.0
			update_led_state(false)

func handle_morse_input(delta: float) -> void:
	if not is_holding_radio: return
	if abs(current_frequency - target_frequency) > 0.3:
		current_state = State.SEARCHING
		signal_hold_timer = 0.0
		is_in_range = false
		morse_progress = ""
		update_led_state(false)
		return

	if not debug_god_mode:
		disconnection_timer += delta
		if disconnection_timer >= next_disconnection_time:
			current_state = State.SEARCHING
			signal_hold_timer = 0.0
			is_in_range = false
			morse_progress = ""
			update_led_state(false)
			current_frequency = snappedf(randf_range(min_frequency, max_frequency) * 2.0, 1.0) / 2.0
			disconnection_timer = 0.0

func check_morse_completion() -> void:
	if morse_progress == target_morse_karakter_ini:
		morse_progress = ""
		indeks_karakter_aktif += 1
		perbarui_target_karakter_morse()
	elif morse_progress.length() >= target_morse_karakter_ini.length():
		morse_progress = ""

func update_led_state(turned_on: bool) -> void:
	if led_mesh:
		led_mesh.material_override = mat_on if turned_on else mat_off

func _on_btn_next_page_pressed() -> void:
	indeks_halaman_aktif = posmod(indeks_halaman_aktif + 1, daftar_halaman_kertas.size())
	perbarui_tampilan_kertas()

func _on_btn_prev_page_pressed() -> void:
	indeks_halaman_aktif = posmod(indeks_halaman_aktif - 1, daftar_halaman_kertas.size())
	perbarui_tampilan_kertas()

func _on_btn_radio_pressed() -> void: toggle_radio_state()
func _on_btn_eyes_button_down() -> void: is_eyes_closed = true
func _on_btn_eyes_button_up() -> void: is_eyes_closed = false
func _on_btn_up_button_down() -> void: is_virtual_up_pressed = true
func _on_btn_up_button_up() -> void: is_virtual_up_pressed = false
func _on_btn_down_button_down() -> void: is_virtual_down_pressed = true
func _on_btn_down_button_up() -> void: is_virtual_down_pressed = false

func _on_btn_morse_button_down() -> void:
	if is_holding_radio and current_state == State.TRANSMITTING:
		is_virtual_morse_holding = true
		virtual_morse_press_time = 0.0

func _on_btn_morse_button_up() -> void:
	if is_holding_radio and current_state == State.TRANSMITTING and is_virtual_morse_holding:
		is_virtual_morse_holding = false
		morse_progress += "." if virtual_morse_press_time < 0.3 else "-"
		check_morse_completion()
	else:
		is_virtual_morse_holding = false
	virtual_morse_press_time = 0.0

func _on_btn_clear_morse_pressed() -> void:
	if is_holding_radio and morse_progress.length() > 0:
		morse_progress = morse_progress.substr(0, morse_progress.length() - 1)

func _on_btn_pilihan_1_pressed() -> void: eksekusi_jawaban(0)
func _on_btn_pilihan_2_pressed() -> void: eksekusi_jawaban(1)
func _on_btnpilihan_3_pressed() -> void: eksekusi_jawaban(2)
func _on_btn_pilihan_4_pressed() -> void: eksekusi_jawaban(3)

## Volume statis: dekat frekuensi target = keras, makin jauh makin pelan
func _hitung_volume_statis() -> float:
	var jarak: float = absf(current_frequency - target_frequency)
	var t: float = clampf(jarak / maxf(jarak_maks_statis, 0.1), 0.0, 1.0)
	return lerpf(volume_statis_dekat_db, volume_statis_jauh_db, t)

# Atur posisi suara anomali ke titik acak di dunia, atau sekitar kamera
func atur_posisi_suara_anomali() -> void:
	if not anomaly_audio: return

	if mode_arah_anomali == 0 and not titik_suara_anomali.is_empty():
		var titik: Node3D = titik_suara_anomali[randi() % titik_suara_anomali.size()]
		if titik:
			anomaly_audio.global_position = titik.global_position
			return

	if camera_node:
		var arah := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		if arah.length() < 0.1: arah = Vector3.FORWARD
		anomaly_audio.global_position = camera_node.global_position + arah.normalized() * jarak_suara_anomali

## Semua suara gameplay difade keluar saat kalah, lalu dihentikan.
## Radio juga dilepas dari sinyal 'finished' supaya tidak diputar ulang.
func _hentikan_audio_gameplay(durasi: float = 0.3) -> void:
	if radio_audio and radio_audio.finished.is_connected(_on_audio_finished):
		radio_audio.finished.disconnect(_on_audio_finished)

	var daftar: Array = [radio_audio, anomaly_audio, jangkrik_audio, click_up, click_down]
	for p in daftar:
		if p == null or not p.playing:
			continue
		var t := create_tween()
		t.tween_property(p, "volume_db", -80.0, durasi)
		t.tween_callback(p.stop)

## Memasang semua suara walkie talkie ke bus SFX supaya ikut slider Efek Suara
func _pasang_bus_sfx() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		push_warning("Bus 'SFX' tidak ditemukan di panel Audio")
		return
	for p in [radio_audio, click_up, click_down, anomaly_audio]:
		if p:
			p.bus = "SFX"
