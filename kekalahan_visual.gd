class_name KekalahanVisual
extends CanvasLayer

signal selesai

@export var anim_player: AnimationPlayer
@export var container: Control
@export var glitch: ColorRect
@export var daftar_suara: Array[EntriSuara] = []
@export var durasi_tahan_skip: float = 0.8
@export var durasi_glitch_masuk: float = 0.2
@export var durasi_beku: float = 0.8
## Batas maksimal audio sekali-bunyi tetap jalan setelah animasi berhenti (detik)
@export var durasi_tunggu_audio_maks: float = 8.0
## Lama fade semua suara saat pindah scene (detik)
@export var durasi_fade_pindah: float = 0.25
@export var tes_langsung: bool = false

@export_group("Glitch Pembuka")
## Kekuatan glitch saat transisi dari gameplay ke kekalahan
@export var kekuatan_glitch_pembuka: float = 1.0
## Lama glitch pembuka mereda (detik)
@export var durasi_glitch_pembuka: float = 0.35

@export_group("Glitch Mati")
## Kekuatan glitch yang bertahan setelah animasi selesai
@export var kekuatan_glitch_mati: float = 0.8
## Kalau aktif, glitch berkedip terus sampai pindah scene
@export var kedip_glitch_mati: bool = true
## Rentang jeda antar kedipan (detik), x = minimum, y = maksimum
@export var interval_kedip: Vector2 = Vector2(0.04, 0.3)

var _viewport: SubViewport
var _anim_enemy: AnimationPlayer

var _players: Array[AudioStreamPlayer] = []
var _sudah_main: Array[bool] = []
var _dihentikan: Array[bool] = []
var _tween_audio: Array[Tween] = []

var _berjalan: bool = false
var _sedang_glitch: bool = false
var _menunggu_audio: bool = false
var _sudah_selesai: bool = false
var _audio_dijeda: bool = false
var _tahan: bool = false
var _waktu_tahan: float = 0.0
var _waktu: float = 0.0
var _waktu_glitch: float = -1.0
var _waktu_akhir: float = -1.0

func _ready() -> void:
	visible = false
	set_process(false)
	glitch.visible = false
	anim_player.animation_finished.connect(_on_animasi_selesai)

	_viewport = container.find_child("SubViewport", true, false) as SubViewport
	_anim_enemy = container.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_matikan_render_model()

	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		var p := AudioStreamPlayer.new()
		p.stream = _siapkan_stream(e)
		p.volume_db = e.volume_db
		p.pitch_scale = e.pitch
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(p)
		_players.append(p)
		_sudah_main.append(false)
		_dihentikan.append(false)

	if tes_langsung:
		call_deferred("mulai")

# Model 3D tidak dirender dan posenya tidak bergerak sampai animasi kalah dimulai
func _matikan_render_model() -> void:
	if _viewport:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _anim_enemy:
		_anim_enemy.stop()

# Kalau suara bertanda Ulang, buat salinan stream yang di-loop oleh audio engine.
# File aslinya tidak diubah.
func _siapkan_stream(e: EntriSuara) -> AudioStream:
	if e.stream == null or not e.ulang:
		return e.stream
	var salinan := e.stream.duplicate() as AudioStream
	if salinan is AudioStreamWAV:
		(salinan as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif "loop" in salinan:
		salinan.set("loop", true)
	return salinan

# --- Glitch ---

func _set_glitch(nilai: float) -> void:
	if glitch == null or glitch.material == null:
		return
	(glitch.material as ShaderMaterial).set_shader_parameter("kekuatan", nilai)

# Burst glitch kuat sebelum animasi kalah dimulai
func _glitch_pembuka() -> void:
	var t := create_tween()
	t.tween_method(_set_glitch, 0.0, kekuatan_glitch_pembuka, 0.05)
	t.tween_method(_set_glitch, kekuatan_glitch_pembuka, kekuatan_glitch_pembuka * 0.2, 0.07)
	t.tween_method(_set_glitch, kekuatan_glitch_pembuka * 0.2, kekuatan_glitch_pembuka, 0.05)
	t.tween_method(_set_glitch, kekuatan_glitch_pembuka, 0.0, durasi_glitch_pembuka)
	await t.finished

# Glitch yang terus berkedip sampai scene berganti (node ini di-free)
func _kedip_glitch() -> void:
	while is_inside_tree() and kedip_glitch_mati:
		_set_glitch(kekuatan_glitch_mati * randf_range(0.6, 1.0))
		await get_tree().create_timer(randf_range(interval_kedip.x, interval_kedip.y)).timeout

# --- Mulai ---

func mulai() -> void:
	visible = true
	container.visible = false
	glitch.visible = true
	_matikan_render_model()
	_set_glitch(0.0)

	_sedang_glitch = false
	_menunggu_audio = false
	_sudah_selesai = false
	_audio_dijeda = false
	_tahan = false
	_waktu_tahan = 0.0
	_waktu = 0.0
	_waktu_glitch = -1.0
	_waktu_akhir = -1.0
	_tween_audio.clear()
	for i in daftar_suara.size():
		_sudah_main[i] = false
		_dihentikan[i] = false
		_players[i].stream_paused = false

	# Gameplay tampil dengan glitch kuat dulu, baru animasi kalah dimulai
	await _glitch_pembuka()

	glitch.visible = false
	if _viewport:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.visible = true
	_berjalan = true
	set_process(true)
	anim_player.play("kekalahan")

# --- Jeda dan lanjut audio (animasi dan glitch tetap jalan) ---

func jeda_audio() -> void:
	if _sudah_selesai or _audio_dijeda:
		return
	_audio_dijeda = true
	for p in _players:
		p.stream_paused = true
	for t in _tween_audio:
		if t.is_valid():
			t.pause()

func lanjut_audio() -> void:
	if not _audio_dijeda:
		return
	_audio_dijeda = false
	for p in _players:
		p.stream_paused = false
	for t in _tween_audio:
		if t.is_valid():
			t.play()

func _buat_tween_audio() -> Tween:
	var masih_hidup: Array[Tween] = []
	for t in _tween_audio:
		if t.is_valid():
			masih_hidup.append(t)
	_tween_audio = masih_hidup

	var t_baru := create_tween()
	if _audio_dijeda:
		t_baru.pause()
	_tween_audio.append(t_baru)
	return t_baru

# Waktu acuan untuk satu suara: dari awal animasi, atau dari saat glitch.
# Mengembalikan -1 kalau acuannya belum mulai.
func _waktu_untuk(e: EntriSuara) -> float:
	if e.mulai_saat_glitch:
		return -1.0 if _waktu_glitch < 0.0 else _waktu - _waktu_glitch
	return _waktu

# --- Proses utama ---

func _process(delta: float) -> void:
	if _sudah_selesai:
		return
	_waktu += delta

	if _tahan and _berjalan:
		_waktu_tahan += delta
		if _waktu_tahan >= durasi_tahan_skip:
			_tahan = false
			_lewati()
			return

	if _audio_dijeda:
		return

	# Putar suara yang sudah sampai waktunya
	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		if _sudah_main[i] or e.stream == null:
			continue
		var w := _waktu_untuk(e)
		if w < 0.0 or w < e.detik_mulai:
			continue
		_sudah_main[i] = true
		_mainkan(i)

	# Hentikan suara yang sudah sampai detik berhentinya
	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		var w := _waktu_untuk(e)
		if _sudah_main[i] and not _dihentikan[i] and e.detik_berhenti > 0.0 and w >= e.detik_berhenti:
			_hentikan(i, e.fade_keluar)

	# Potong suara saat sudah sampai selesai_di_file di dalam file audionya
	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		var p := _players[i]
		if not _sudah_main[i] or _dihentikan[i] or e.selesai_di_file <= 0.0:
			continue
		if not p.playing or p.get_playback_position() < e.selesai_di_file:
			continue
		if e.ulang:
			p.play(e.mulai_di_file)
		else:
			_hentikan(i, e.fade_keluar)

	# Cadangan: ulangi suara bertanda Ulang yang sudah berhenti sendiri
	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		if not _sudah_main[i] or _dihentikan[i] or not e.ulang or _players[i].playing:
			continue
		var w := _waktu_untuk(e)
		if e.detik_berhenti > 0.0 and w >= e.detik_berhenti:
			continue
		_mainkan(i)

	# Setelah animasi berhenti, tunggu suara sekali-bunyi yang masih berjalan
	if _menunggu_audio:
		if not _masih_perlu_tunggu() or _waktu - _waktu_akhir >= durasi_tunggu_audio_maks:
			_selesaikan()

func _masih_perlu_tunggu() -> bool:
	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		# Suara loop tidak ditunggu, dia ikut berhenti saat pindah scene
		if _players[i].playing and not e.ulang:
			return true
		# Suara yang dijadwalkan mulai sebentar lagi juga ditunggu
		if not _sudah_main[i] and e.stream != null:
			var w := _waktu_untuk(e)
			if w < 0.0 or e.detik_mulai - w <= durasi_tunggu_audio_maks:
				return true
	return false

func _input(event: InputEvent) -> void:
	if not _berjalan or _audio_dijeda:
		return
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			_tahan = true
			_waktu_tahan = 0.0
		else:
			_tahan = false

# --- Suara ---

func _mainkan(i: int) -> void:
	var e: EntriSuara = daftar_suara[i]
	var p := _players[i]
	p.play(e.mulai_di_file)
	if e.fade_masuk <= 0.0:
		p.volume_db = e.volume_db
		return
	p.volume_db = -60.0
	var t := _buat_tween_audio()
	t.tween_property(p, "volume_db", e.volume_db, e.fade_masuk)

func _hentikan(i: int, durasi: float) -> void:
	_dihentikan[i] = true
	var p := _players[i]
	var volume_awal: float = daftar_suara[i].volume_db
	if durasi <= 0.0 or not p.playing:
		p.stop()
		return
	var t := _buat_tween_audio()
	t.tween_property(p, "volume_db", -60.0, durasi)
	t.tween_callback(func():
		p.stop()
		p.volume_db = volume_awal)

# --- Skip dan selesai ---

func _lewati() -> void:
	_audio_dijeda = false
	for i in daftar_suara.size():
		var e: EntriSuara = daftar_suara[i]
		if e.stream == null:
			_sudah_main[i] = true
			continue
		# Suara yang terikat glitch tetap dibiarkan, akan dimulai saat glitch muncul
		if e.mulai_saat_glitch:
			continue
		if e.ikut_saat_skip:
			if not _sudah_main[i]:
				_mainkan(i)
		else:
			_players[i].stop()
			_dihentikan[i] = true
		_sudah_main[i] = true
	anim_player.seek(anim_player.current_animation_length, true)
	_on_animasi_selesai(&"")

func _on_animasi_selesai(_nama: StringName) -> void:
	if _sedang_glitch or _sudah_selesai:
		return
	_sedang_glitch = true
	_berjalan = false
	_waktu_glitch = _waktu
	glitch.visible = true
	_set_glitch(0.0)

	var t := create_tween()
	t.tween_method(_set_glitch, 0.0, kekuatan_glitch_mati, durasi_glitch_masuk)
	t.tween_interval(durasi_beku)
	t.tween_callback(_akhiri)
	t.tween_callback(_kedip_glitch)

func _akhiri() -> void:
	if _menunggu_audio or _sudah_selesai:
		return
	_menunggu_audio = true
	_waktu_akhir = _waktu
	# Audio yang sempat dijeda harus dilanjutkan supaya bisa selesai
	if _audio_dijeda:
		lanjut_audio()

func _selesaikan() -> void:
	if _sudah_selesai:
		return
	_sudah_selesai = true
	set_process(false)

	# Semua suara yang masih berbunyi (termasuk loop) difade keluar dulu
	var ada_bunyi := false
	for i in daftar_suara.size():
		if _players[i].playing:
			_hentikan(i, durasi_fade_pindah)
			ada_bunyi = true

	if ada_bunyi:
		var t := _buat_tween_audio()
		t.tween_interval(durasi_fade_pindah)
		t.tween_callback(func(): selesai.emit())
	else:
		selesai.emit()
