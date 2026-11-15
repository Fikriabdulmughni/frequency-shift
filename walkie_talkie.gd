extends Node3D

@export_category("Pengaturan Layar")
@export var mat_off: StandardMaterial3D
@export var mat_on: StandardMaterial3D
@export var mesh_layar: MeshInstance3D

@export_category("Audio Glitch Acak")
@export var suara_glitch: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_radio: float = 0.0

@export_category("Audio Klik Layar")
@export var suara_klik: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db_klik: float = 0.0
@export_range(0.0, 0.3, 0.01) var variasi_pitch_klik: float = 0.05

var audio_3d: AudioStreamPlayer3D
var audio_klik: AudioStreamPlayer3D
var timer: float = 0.0
var jeda_berikutnya: float = 5.0
var sedang_glitch: bool = false
var paksa_nyala: bool = false

func _ready() -> void:
	audio_3d = find_child("AudioStreamPlayer3D", true, false) as AudioStreamPlayer3D

	# Buat player khusus untuk klik, terpisah dari suara glitch
	audio_klik = AudioStreamPlayer3D.new()
	add_child(audio_klik)
	audio_klik.stream = suara_klik
	audio_klik.volume_db = volume_db_klik

	if mesh_layar and mat_off:
		mesh_layar.material_override = mat_off
	jeda_berikutnya = randf_range(4.0, 9.0)

func _process(delta: float) -> void:
	if paksa_nyala: return

	timer += delta
	if not sedang_glitch and timer >= jeda_berikutnya:
		mulai_glitch_acak()

func mulai_glitch_acak() -> void:
	sedang_glitch = true
	timer = 0.0

	if suara_glitch and audio_3d:
		audio_3d.stream = suara_glitch
		audio_3d.volume_db = volume_db_radio
		audio_3d.play(0.07)

	_kedip_layar(randi_range(2, 5))

func _kedip_layar(sisa: int) -> void:
	if sisa > 0:
		if mesh_layar:
			var aktif = (mesh_layar.material_override == mat_on)
			mesh_layar.material_override = mat_off if aktif else mat_on
		_bunyi_klik()  # setiap kedip, satu klik
		var t = get_tree().create_timer(randf_range(0.05, 0.12))
		if t:
			t.timeout.connect(func(): _kedip_layar(sisa - 1))
	else:
		if mesh_layar and not paksa_nyala:
			mesh_layar.material_override = mat_off
		sedang_glitch = false
		jeda_berikutnya = randf_range(6.0, 15.0)

func _bunyi_klik() -> void:
	if not suara_klik or not audio_klik:
		return
	# Pitch sedikit acak supaya klik tidak terdengar seperti rekaman yang diulang
	audio_klik.pitch_scale = 1.0 + randf_range(-variasi_pitch_klik, variasi_pitch_klik)
	audio_klik.play()  # kalau masih berbunyi, play() akan mengulang dari awal

func nyalakan_permanen() -> void:
	paksa_nyala = true
	if mesh_layar and mat_on:
		mesh_layar.material_override = mat_on
	if suara_glitch and audio_3d:
		audio_3d.stream = suara_glitch
		audio_3d.volume_db = volume_db_radio
		audio_3d.play()
	_bunyi_klik()
