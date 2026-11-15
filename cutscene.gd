extends Node3D

@export_file("res://game.tscn") var scene_game_tujuan: String

@onready var label_narasi: Label = $CanvasLayer/LabelNarasi
@onready var kamera_utama: Camera3D = $Camera3D
@onready var vignet_bawah: TextureRect = $CanvasLayer/VignetBawah
@onready var audio_ketik: AudioStreamPlayer = $CanvasLayer/AudioKetik

@export var arsip_cutscene: Array[ArsipAdegan] = []
@export var mulai_dari_adegan: int = 0
## Teks yang muncul saat teks sedang diketik
@export var teks_percepat: String = ">> Percepat"
## Simbol yang muncul setelah teks selesai, sebagai tanda lanjut. Ganti ke "▶" atau "↓" jika perlu.
@export var simbol_lanjut: String = "▼"
## Berapa detik harus ditahan untuk melewati cutscene
@export var durasi_tahan_lewati: float = 1.5

var indeks_langkah: int = 0
var sedang_transisi: bool = false
var cooldown_klik: float = 0.0
var tween_teks: Tween
var tween_swing: Tween
var tween_shake: Tween
var tween_vignet: Tween
var tween_fade: Tween
var tween_kamera: Tween
var tween_indikator: Tween
var tween_auto: Tween
var tween_audio: Dictionary = {}
var tween_potong: Dictionary = {}
var layar_hitam: ColorRect
var indikator_teks: Label

var timer_audio_crop: float = 0.0
const BATAS_DURASI_AUDIO: float = 0.33
const VOLUME_SENYAP: float = -80.0

var posisi_awal_label: Vector2
var default_camera_fov: float = 75.0

var _sedang_tahan: bool = false
var _waktu_tahan: float = 0.0

func _ready() -> void:
	if vignet_bawah:
		vignet_bawah.modulate.a = 0.0

	if label_narasi:
		posisi_awal_label = label_narasi.position

	if kamera_utama:
		default_camera_fov = kamera_utama.fov

	_buat_layar_hitam()
	_buat_indikator()

	# Lompat ke adegan yang dipilih. Adegan sebelumnya dijalankan diam-diam
	# agar kamera dan objek sudah di posisi yang benar.
	var mulai: int = clampi(mulai_dari_adegan, 0, max(arsip_cutscene.size() - 1, 0))
	for i in range(mulai):
		var data_lewat: ArsipAdegan = arsip_cutscene[i]
		if data_lewat:
			eksekusi_semua_aksi(data_lewat, true)

	indeks_langkah = mulai
	tampilkan_langkah_aktif()

func _buat_layar_hitam() -> void:
	layar_hitam = ColorRect.new()
	layar_hitam.color = Color(0, 0, 0, 0)
	layar_hitam.set_anchors_preset(Control.PRESET_FULL_RECT)
	layar_hitam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layar_hitam.visible = false
	$CanvasLayer.add_child(layar_hitam)
	# Layar hitam di atas vignet, lalu label teks di atas layar hitam.
	# Dengan begitu hanya teks yang tetap terlihat saat layar hitam penuh aktif.
	$CanvasLayer.move_child(layar_hitam, -1)
	$CanvasLayer.move_child(label_narasi, -1)

func _buat_indikator() -> void:
	indikator_teks = Label.new()
	indikator_teks.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	indikator_teks.offset_left = -260
	indikator_teks.offset_top = -60
	indikator_teks.offset_right = -40
	indikator_teks.offset_bottom = -20
	indikator_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	indikator_teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indikator_teks.visible = false
	$CanvasLayer.add_child(indikator_teks)
	# Paling depan, supaya tetap terlihat di atas layar hitam penuh
	$CanvasLayer.move_child(indikator_teks, -1)

# mode 0 = sembunyi, 1 = teks percepat (saat mengetik), 2 = simbol lanjut berkedip (teks selesai)
func _set_indikator(mode: int) -> void:
	if tween_indikator and tween_indikator.is_running(): tween_indikator.kill()
	indikator_teks.modulate.a = 1.0

	match mode:
		0:
			indikator_teks.visible = false
		1:
			indikator_teks.visible = true
			indikator_teks.text = teks_percepat
		2:
			indikator_teks.visible = true
			indikator_teks.text = simbol_lanjut
			tween_indikator = create_tween().set_loops()
			tween_indikator.tween_property(indikator_teks, "modulate:a", 0.2, 0.5)
			tween_indikator.tween_property(indikator_teks, "modulate:a", 1.0, 0.5)

func _process(delta: float) -> void:
	# Hitung tahan untuk lewati cutscene
	if _sedang_tahan and not sedang_transisi:
		_waktu_tahan += delta
		if _waktu_tahan >= durasi_tahan_lewati:
			_sedang_tahan = false
			_lewati_cutscene()

	if cooldown_klik > 0.0:
		cooldown_klik -= delta

	if tween_teks and tween_teks.is_running() and audio_ketik:
		if not audio_ketik.playing:
			audio_ketik.play()
			timer_audio_crop = 0.0
		else:
			timer_audio_crop += delta
			if timer_audio_crop >= BATAS_DURASI_AUDIO:
				audio_ketik.stop()

func _input(event: InputEvent) -> void:
	# Catat kapan layar atau klik kiri ditekan dan dilepas
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			_sedang_tahan = true
			_waktu_tahan = 0.0
		else:
			_sedang_tahan = false

	if sedang_transisi: return
	if cooldown_klik > 0.0: return

	var data_adegan_cek: ArsipAdegan = arsip_cutscene[indeks_langkah] if indeks_langkah < arsip_cutscene.size() else null
	if data_adegan_cek and data_adegan_cek.tipe_transisi == 3 and not data_adegan_cek.pakai_fade:
		return

	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		if tween_teks and tween_teks.is_running():
			# Adegan ini mengunci teks: klik diabaikan sampai teks selesai
			if data_adegan_cek and data_adegan_cek.tunggu_teks_selesai:
				return

			# Adegan biasa: klik menampilkan semua teks sekaligus
			tween_teks.kill()
			if tween_swing and tween_swing.is_running(): tween_swing.kill()
			if tween_vignet and tween_vignet.is_running(): tween_vignet.kill()

			label_narasi.position = posisi_awal_label
			label_narasi.modulate.a = 1.0
			label_narasi.visible_characters = -1
			if vignet_bawah: vignet_bawah.modulate.a = 0.85

			if audio_ketik: audio_ketik.stop()
			_set_indikator(2)
			# Teks sudah selesai, jadi timer auto lanjut bisa mulai menghitung jeda
			_jadwalkan_auto_lanjut_setelah_teks(data_adegan_cek)
			cooldown_klik = 0.1
			return

		# Klik manual: pindah adegan dan batalkan timer auto lanjut
		indeks_langkah += 1
		cooldown_klik = 0.2

		if arsip_cutscene.size() > 0 and indeks_langkah < arsip_cutscene.size():
			tampilkan_langkah_aktif()
		else:
			selesai_cutscene()

# --- Lewati cutscene dengan tahan ---

func _lewati_cutscene() -> void:
	sedang_transisi = true

	# Hentikan semua timer dan tween adegan agar tidak ada pindah scene dobel
	for t in [tween_teks, tween_swing, tween_vignet, tween_fade, tween_kamera, tween_auto, tween_shake]:
		if t and t.is_running(): t.kill()
	for t in tween_audio.values():
		if t and t.is_running(): t.kill()
	for t in tween_potong.values():
		if t and t.is_running(): t.kill()

	_set_indikator(0)
	if audio_ketik: audio_ketik.stop()

	# Layar menggelap, lalu pindah ke scene gameplay
	layar_hitam.visible = true
	var t_fade := create_tween()
	t_fade.tween_property(layar_hitam, "color:a", 1.0, 0.4)
	t_fade.tween_callback(selesai_cutscene)

func tampilkan_langkah_aktif() -> void:
	if indeks_langkah >= arsip_cutscene.size():
		return

	# Hentikan semua sisa aksi dan timer adegan sebelumnya
	if tween_kamera and tween_kamera.is_running(): tween_kamera.kill()
	if tween_fade and tween_fade.is_running(): tween_fade.kill()
	if tween_auto and tween_auto.is_running(): tween_auto.kill()
	_set_indikator(0)

	var data_adegan: ArsipAdegan = arsip_cutscene[indeks_langkah]
	if not data_adegan: return

	if data_adegan.pakai_fade:
		jalankan_adegan_dengan_fade(data_adegan)
	else:
		eksekusi_semua_aksi(data_adegan)

# Urutan: layar menggelap -> kamera & objek berpindah saat gelap -> jeda -> layar terang (atau tetap hitam jika Layar Hitam Penuh) -> teks muncul
func jalankan_adegan_dengan_fade(data_adegan: ArsipAdegan) -> void:
	sedang_transisi = true
	bersihkan_teks()

	layar_hitam.color.a = 0.0
	layar_hitam.visible = true

	tween_fade = create_tween()
	tween_fade.tween_property(layar_hitam, "color:a", 1.0, data_adegan.durasi_fade_masuk)
	tween_fade.tween_callback(func(): eksekusi_semua_aksi(data_adegan, true))
	tween_fade.tween_interval(data_adegan.durasi_jeda_gelap)

	# Jika Layar Hitam Penuh aktif, layar dibiarkan hitam dan hanya teks yang muncul
	if not data_adegan.layar_hitam_penuh:
		tween_fade.tween_property(layar_hitam, "color:a", 0.0, data_adegan.durasi_fade_keluar)

	tween_fade.tween_callback(func():
		layar_hitam.visible = data_adegan.layar_hitam_penuh
		layar_hitam.color.a = 1.0 if data_adegan.layar_hitam_penuh else 0.0
		sedang_transisi = false
		cooldown_klik = 0.2
		munculkan_teks_dan_vignet(data_adegan)
	)

func bersihkan_teks() -> void:
	if tween_teks and tween_teks.is_running(): tween_teks.kill()
	if tween_swing and tween_swing.is_running(): tween_swing.kill()
	if tween_vignet and tween_vignet.is_running(): tween_vignet.kill()
	if label_narasi: label_narasi.visible = false
	if vignet_bawah: vignet_bawah.modulate.a = 0.0
	if audio_ketik: audio_ketik.stop()
	_set_indikator(0)

# dalam_fade = true berarti dipanggil saat layar gelap: perubahan langsung, teks diurus pemanggil
func eksekusi_semua_aksi(data_adegan: ArsipAdegan, dalam_fade: bool = false) -> void:
	# Layar hitam penuh untuk adegan biasa (adegan fade mengurus layarnya sendiri)
	if not dalam_fade and not data_adegan.pakai_fade:
		layar_hitam.color.a = 1.0 if data_adegan.layar_hitam_penuh else 0.0
		layar_hitam.visible = data_adegan.layar_hitam_penuh

	var objek: Node3D = null
	if not data_adegan.target_objek_node.is_empty():
		objek = get_node_or_null(data_adegan.target_objek_node) as Node3D

	if objek:
		if data_adegan.atur_posisi_objek_manual:
			match data_adegan.aksi_objek:
				1:
					if dalam_fade:
						objek.global_position = data_adegan.koordinat_tujuan_objek
					else:
						var tween_objek = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
						tween_objek.tween_property(objek, "global_position", data_adegan.koordinat_tujuan_objek, data_adegan.durasi_transisi_objek)
				2:
					objek.global_position = data_adegan.koordinat_tujuan_objek
				3:
					pass
				4:
					objek.visible = false
				5:
					objek.visible = true

		if data_adegan.atur_rotasi_objek:
			if dalam_fade:
				objek.global_rotation_degrees = data_adegan.rotasi_tujuan_objek
			else:
				var tween_rotasi = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tween_rotasi.tween_property(objek, "global_rotation_degrees", data_adegan.rotasi_tujuan_objek, data_adegan.durasi_transisi_objek)

	if data_adegan.aktifkan_getaran:
		jalankan_efek_getaran(data_adegan.kekuatan_getaran)

	eksekusi_filter_audio_dari_resource(data_adegan)

	eksekusi_kontrol_audio(data_adegan.audio_player_1, data_adegan.aksi_audio_1, data_adegan.file_suara_1, data_adegan.volume_db_1, data_adegan.fade_masuk_1, data_adegan.fade_keluar_1, data_adegan.kurva_audio, data_adegan.mulai_potong_1, data_adegan.akhir_potong_1, data_adegan.loop_audio_1)
	eksekusi_kontrol_audio(data_adegan.audio_player_2, data_adegan.aksi_audio_2, data_adegan.file_suara_2, data_adegan.volume_db_2, data_adegan.fade_masuk_2, data_adegan.fade_keluar_2, data_adegan.kurva_audio, data_adegan.mulai_potong_2, data_adegan.akhir_potong_2, data_adegan.loop_audio_2)
	eksekusi_kontrol_audio(data_adegan.audio_player_3, data_adegan.aksi_audio_3, data_adegan.file_suara_3, data_adegan.volume_db_3, data_adegan.fade_masuk_3, data_adegan.fade_keluar_3, data_adegan.kurva_audio, data_adegan.mulai_potong_3, data_adegan.akhir_potong_3, data_adegan.loop_audio_3)

	if not data_adegan.anim_player_1.is_empty():
		var target_anim_1 = get_node_or_null(data_adegan.anim_player_1) as AnimationPlayer
		if target_anim_1 and target_anim_1.has_animation(data_adegan.nama_animasi_1):
			if data_adegan.aksi_animasi_1 == 1: target_anim_1.play(data_adegan.nama_animasi_1)
			elif data_adegan.aksi_animasi_1 == 2: target_anim_1.stop()

	if not data_adegan.anim_player_2.is_empty():
		var target_anim_2 = get_node_or_null(data_adegan.anim_player_2) as AnimationPlayer
		if target_anim_2 and target_anim_2.has_animation(data_adegan.nama_animasi_2):
			if data_adegan.aksi_animasi_2 == 1: target_anim_2.play(data_adegan.nama_animasi_2)
			elif data_adegan.aksi_animasi_2 == 2: target_anim_2.stop()

	var target_marker: Marker3D = null
	if not data_adegan.target_marker.is_empty():
		target_marker = get_node_or_null(data_adegan.target_marker) as Marker3D

	if dalam_fade:
		if target_marker:
			pasang_kamera_instan(target_marker)
		return

	if target_marker:
		eksekusi_transisi_kamera(target_marker, data_adegan.tipe_transisi, data_adegan)
	else:
		munculkan_teks_dan_vignet(data_adegan)

func pasang_kamera_instan(target_marker: Marker3D) -> void:
	kamera_utama.global_position = target_marker.global_position
	kamera_utama.global_rotation_degrees = target_marker.global_rotation_degrees
	kamera_utama.fov = default_camera_fov

# --- AUDIO: FADE, PEMOTONGAN, DAN LOOP ---
func eksekusi_kontrol_audio(path_node: NodePath, aksi: int, file_suara: AudioStream, vol_db: float, fade_masuk: float, fade_keluar: float, kurva: int, mulai_potong: float, akhir_potong: float, loop: bool) -> void:
	if path_node.is_empty() or aksi == 0: return
	var player = get_node_or_null(path_node)
	if not player: return

	var trans: int = _ambil_trans(kurva)
	var id: int = player.get_instance_id()
	if tween_audio.has(id) and tween_audio[id] and tween_audio[id].is_running():
		tween_audio[id].kill()
	if tween_potong.has(id) and tween_potong[id] and tween_potong[id].is_running():
		tween_potong[id].kill()

	match aksi:
		1: # Putar Baru
			if file_suara and player.has_method("play"):
				player.stream = file_suara
				player.stream_paused = false
				var mulai: float = max(mulai_potong, 0.0)
				player.play(mulai)
				_fade_volume(player, vol_db, fade_masuk, trans, true)
				_jadwalkan_potong(player, {
					"vol": vol_db,
					"mulai": mulai,
					"akhir": akhir_potong,
					"fade_masuk": fade_masuk,
					"fade_keluar": fade_keluar,
					"trans": trans,
					"loop": loop,
				})
		2: # Lanjutkan / Resume
			if player.has_method("play"):
				var senyap: bool = not player.playing or player.stream_paused
				player.stream_paused = false
				if not player.playing:
					player.play()
				_fade_volume(player, vol_db, fade_masuk, trans, senyap)
		3: # Pause
			if "stream_paused" in player:
				if fade_keluar > 0.0 and player.playing:
					var t := create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
					t.tween_property(player, "volume_db", VOLUME_SENYAP, fade_keluar)
					t.tween_callback(func():
						player.stream_paused = true
						player.volume_db = vol_db)
					tween_audio[id] = t
				else:
					player.stream_paused = true
		4: # Stop
			if player.has_method("stop") and "playing" in player and player.playing:
				if fade_keluar > 0.0:
					var t := create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
					t.tween_property(player, "volume_db", VOLUME_SENYAP, fade_keluar)
					t.tween_callback(func():
						player.stop()
						player.volume_db = vol_db)
					tween_audio[id] = t
				else:
					player.stop()
					player.volume_db = vol_db

func _jadwalkan_potong(player, opsi: Dictionary) -> void:
	var mulai: float = opsi["mulai"]
	var selesai: float = _akhir_segmen(player, opsi)
	var panjang_segmen: float = selesai - mulai
	if panjang_segmen <= 0.0: return

	var tunggu: float = panjang_segmen
	if not opsi["loop"]:
		tunggu = max(panjang_segmen - max(opsi["fade_keluar"], 0.0), 0.0)

	var t := create_tween()
	t.tween_interval(tunggu)
	t.tween_callback(func(): _fade_keluar_lalu_akhiri(player, opsi))
	tween_potong[player.get_instance_id()] = t

func _akhir_segmen(player, opsi: Dictionary) -> float:
	if opsi["akhir"] > opsi["mulai"]:
		return opsi["akhir"]
	if player.stream:
		return player.stream.get_length()
	return 0.0

func _fade_keluar_lalu_akhiri(player, opsi: Dictionary) -> void:
	if not is_instance_valid(player): return
	var id: int = player.get_instance_id()

	if tween_audio.has(id) and tween_audio[id] and tween_audio[id].is_running():
		tween_audio[id].kill()

	var fade_keluar: float = opsi["fade_keluar"]
	if opsi["loop"] or fade_keluar <= 0.0:
		_akhiri_segmen(player, opsi)
		return

	var t := create_tween().set_trans(opsi["trans"]).set_ease(Tween.EASE_OUT)
	t.tween_property(player, "volume_db", VOLUME_SENYAP, fade_keluar)
	t.tween_callback(func(): _akhiri_segmen(player, opsi))
	tween_audio[id] = t

func _akhiri_segmen(player, opsi: Dictionary) -> void:
	if not is_instance_valid(player): return

	if opsi["loop"]:
		player.stream_paused = false
		player.play(opsi["mulai"])
		player.volume_db = opsi["vol"]
		_jadwalkan_potong(player, opsi)
	else:
		player.stop()
		player.volume_db = opsi["vol"]

func _fade_volume(player, tujuan: float, durasi: float, trans: int, dari_senyap: bool) -> void:
	if durasi <= 0.0:
		player.volume_db = tujuan
		return
	if dari_senyap:
		player.volume_db = VOLUME_SENYAP
	var t := create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
	t.tween_property(player, "volume_db", tujuan, durasi)
	tween_audio[player.get_instance_id()] = t

func _ambil_trans(kurva: int) -> int:
	match kurva:
		0: return Tween.TRANS_LINEAR
		2: return Tween.TRANS_SINE
		_: return Tween.TRANS_CUBIC

# --- FILTER AUDIO (bus PabrikIndoor) ---
func eksekusi_filter_audio_dari_resource(data_adegan: ArsipAdegan) -> void:
	var aksi: int = data_adegan.aksi_filter_audio
	if aksi == 0:
		return

	var effect: AudioEffectLowPassFilter = _ambil_filter_pabrik()
	if effect == null:
		return

	match aksi:
		1:
			var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "cutoff_hz", 800.0, data_adegan.durasi_transisi_filter)
		2:
			effect.cutoff_hz = 800.0
		3:
			var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(effect, "cutoff_hz", 20000.0, data_adegan.durasi_transisi_filter)

## Mengambil LowPassFilter dari bus PabrikIndoor. Kalau bus belum punya efek, efeknya dibuat.
func _ambil_filter_pabrik() -> AudioEffectLowPassFilter:
	var bus_index: int = AudioServer.get_bus_index("PabrikIndoor")
	if bus_index == -1:
		push_warning("Bus 'PabrikIndoor' tidak ditemukan di panel Audio")
		return null

	if AudioServer.get_bus_effect_count(bus_index) == 0:
		AudioServer.add_bus_effect(bus_index, AudioEffectLowPassFilter.new())

	return AudioServer.get_bus_effect(bus_index, 0) as AudioEffectLowPassFilter

func eksekusi_transisi_kamera(target_marker: Marker3D, jenis: int, data_adegan: ArsipAdegan) -> void:
	if not target_marker or not kamera_utama: return

	match jenis:
		0: # Slide
			tween_kamera = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween_kamera.tween_property(kamera_utama, "global_position", target_marker.global_position, 1.2)
			tween_kamera.tween_property(kamera_utama, "global_rotation_degrees", target_marker.global_rotation_degrees, 1.2)
			tween_kamera.tween_property(kamera_utama, "fov", default_camera_fov, 1.2)
			tween_kamera.chain().tween_callback(func(): munculkan_teks_dan_vignet(data_adegan))

		1: # Blink
			kamera_utama.global_position = target_marker.global_position
			kamera_utama.global_rotation_degrees = target_marker.global_rotation_degrees
			kamera_utama.fov = default_camera_fov
			munculkan_teks_dan_vignet(data_adegan)

		2: # Zoom Sinematik
			tween_kamera = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween_kamera.tween_property(kamera_utama, "global_position", target_marker.global_position, data_adegan.durasi_zoom)
			tween_kamera.tween_property(kamera_utama, "global_rotation_degrees", target_marker.global_rotation_degrees, data_adegan.durasi_zoom)
			tween_kamera.tween_property(kamera_utama, "fov", data_adegan.tingkat_zoom, data_adegan.durasi_zoom)
			tween_kamera.chain().tween_callback(func(): munculkan_teks_dan_vignet(data_adegan))

		3: # Cinematic Slide: pindah otomatis setelah kamera selesai bergerak
			var durasi_geser = data_adegan.durasi_gerak_kamera
			tween_kamera = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween_kamera.tween_property(kamera_utama, "global_position", target_marker.global_position, durasi_geser)
			tween_kamera.tween_property(kamera_utama, "global_rotation_degrees", target_marker.global_rotation_degrees, durasi_geser)
			tween_kamera.tween_property(kamera_utama, "fov", default_camera_fov, durasi_geser)
			munculkan_teks_dan_vignet(data_adegan)

			tween_auto = create_tween()
			tween_auto.tween_interval(durasi_geser)
			tween_auto.tween_callback(_on_auto_next_triggered)

func munculkan_teks_dan_vignet(data_adegan: ArsipAdegan) -> void:
	if not label_narasi: return

	if data_adegan.teks_narasi.strip_edges().is_empty():
		label_narasi.visible = false
		_set_indikator(0)
		if vignet_bawah:
			if tween_vignet and tween_vignet.is_running(): tween_vignet.kill()
			tween_vignet = create_tween()
			tween_vignet.tween_property(vignet_bawah, "modulate:a", 0.0, 0.5)
		# Tanpa teks: timer auto lanjut langsung menghitung dari jeda
		_jadwalkan_auto_lanjut(data_adegan, 0.0)
	else:
		label_narasi.visible = true
		label_narasi.modulate = data_adegan.warna_teks
		var teks_tujuan: String = tr(data_adegan.teks_narasi)
		label_narasi.text = teks_tujuan
		label_narasi.visible_characters = 0

		if tween_teks and tween_teks.is_running(): tween_teks.kill()
		if tween_swing and tween_swing.is_running(): tween_swing.kill()
		if tween_vignet and tween_vignet.is_running(): tween_vignet.kill()

		if vignet_bawah:
			vignet_bawah.position.y = 50
			vignet_bawah.modulate.a = 0.0

			tween_vignet = create_tween()
			tween_vignet.set_parallel(true)
			tween_vignet.set_trans(Tween.TRANS_CUBIC)
			tween_vignet.set_ease(Tween.EASE_OUT)

			tween_vignet.tween_property(vignet_bawah, "modulate:a", 0.85, 0.6)
			tween_vignet.tween_property(vignet_bawah, "position:y", 0.0, 0.6)

		label_narasi.position = posisi_awal_label + Vector2(0, 40)
		label_narasi.modulate.a = 0.0

		tween_swing = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_swing.tween_property(label_narasi, "position", posisi_awal_label, 0.4)
		tween_swing.tween_property(label_narasi, "modulate:a", data_adegan.warna_teks.a, 0.3)

		var total_karakter = teks_tujuan.length()
		var durasi_ketik = total_karakter * 0.03

		tween_teks = create_tween()
		tween_teks.tween_property(label_narasi, "visible_characters", total_karakter, durasi_ketik)

		# Saat mengetik: tampilkan teks percepat, kecuali adegan yang mengunci teks
		if data_adegan.tunggu_teks_selesai:
			_set_indikator(0)
		else:
			_set_indikator(1)

		if audio_ketik and not audio_ketik.playing:
			audio_ketik.play()
			timer_audio_crop = 0.0

		# Timer auto lanjut dimulai setelah teks selesai diketik
		tween_teks.tween_callback(func():
			if audio_ketik: audio_ketik.stop()
			_set_indikator(2)
			_jadwalkan_auto_lanjut_setelah_teks(data_adegan)
		)

# Dipanggil setelah teks selesai (otomatis atau karena klik untuk menampilkan semua teks)
func _jadwalkan_auto_lanjut_setelah_teks(data_adegan: ArsipAdegan) -> void:
	_jadwalkan_auto_lanjut(data_adegan, 0.0)

# Auto lanjut: setelah jeda, pindah sendiri ke adegan berikutnya.
# Cinematic Slide sudah punya timer sendiri, jadi dilewati agar tidak tumpang tindih.
func _jadwalkan_auto_lanjut(data_adegan: ArsipAdegan, _durasi_ketik: float) -> void:
	if not data_adegan: return
	if not data_adegan.auto_lanjut: return
	if data_adegan.tipe_transisi == 3 and not data_adegan.pakai_fade: return

	if tween_auto and tween_auto.is_running(): tween_auto.kill()
	tween_auto = create_tween()
	tween_auto.tween_interval(max(data_adegan.jeda_auto_lanjut, 0.0))
	tween_auto.tween_callback(_on_auto_next_triggered)

func _on_auto_next_triggered() -> void:
	indeks_langkah += 1
	if arsip_cutscene.size() > 0 and indeks_langkah < arsip_cutscene.size():
		tampilkan_langkah_aktif()
	else:
		selesai_cutscene()

func jalankan_efek_getaran(kekuatan: float) -> void:
	if tween_shake and tween_shake.is_running(): tween_shake.kill()
	tween_shake = create_tween().set_loops(4)
	tween_shake.tween_property(kamera_utama, "h_offset", randf_range(-kekuatan, kekuatan), 0.05)
	tween_shake.tween_property(kamera_utama, "v_offset", randf_range(-kekuatan, kekuatan), 0.05)
	tween_shake.chain().tween_property(kamera_utama, "h_offset", 0.0, 0.05)
	tween_shake.chain().tween_property(kamera_utama, "v_offset", 0.0, 0.05)

func selesai_cutscene() -> void:
	sedang_transisi = true
	if audio_ketik: audio_ketik.stop()
	get_tree().change_scene_to_file(scene_game_tujuan)
