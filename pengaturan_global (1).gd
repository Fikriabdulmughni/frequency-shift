extends Node
## Autoload "Pengaturan" (Project Settings > Globals > Autoload).
## Menyimpan, menerapkan, dan menyimpan pengaturan ke user://pengaturan.cfg

signal berubah(kunci: String)

const FILE_SIMPAN: String = "user://pengaturan.cfg"
const BAGIAN_CFG: String = "pengaturan"
const BUS_MUSIK: String = "Musik"
const BUS_SFX: String = "SFX"
const GRUP_TOMBOL_SENTUH: String = "tombol_sentuh"

const RESOLUSI_RENDER: PackedFloat32Array = [0.5, 0.67, 0.8, 1.0]
const UKURAN_BAYANGAN: PackedInt32Array = [1024, 2048, 4096]
const BATAS_FPS: PackedInt32Array = [30, 60, 0]
const KUNCI_GRAFIS: PackedStringArray = ["resolusi_render", "bayangan", "kualitas_bayangan", "glow", "ssao", "batas_fps"]
## Urutan harus sama dengan OPSI_BAHASA di panel_pengaturan.gd
const KODE_BAHASA: PackedStringArray = ["id", "en"]

var nilai: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	nilai = _nilai_default()
	_pastikan_bus()
	muat()
	set_bahasa(int(nilai["bahasa"]))
	terapkan_audio()
	terapkan_grafis()


func _nilai_default() -> Dictionary:
	return {
		"vol_master": 1.0,
		"vol_musik": 0.8,
		"vol_sfx": 1.0,
		"preset_grafis": 1,
		"resolusi_render": 2,
		"bayangan": true,
		"kualitas_bayangan": 0,
		"glow": true,
		"ssao": false,
		"batas_fps": 1,
		"kesulitan": 1,
		"kecepatan_tuning": 1.0,
		"getaran_kamera": 1.0,
		"efek_glitch": true,
		"getar_haptic": true,
		"ukuran_tombol": 1.0,
		"bahasa": 0,
	}


# ---------------------------------------------------------------
# Simpan & muat
# ---------------------------------------------------------------
func muat() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(FILE_SIMPAN) != OK:
		return
	for k in nilai.keys():
		if cfg.has_section_key(BAGIAN_CFG, str(k)):
			nilai[k] = cfg.get_value(BAGIAN_CFG, str(k))


func simpan() -> void:
	var cfg := ConfigFile.new()
	for k in nilai.keys():
		cfg.set_value(BAGIAN_CFG, str(k), nilai[k])
	cfg.save(FILE_SIMPAN)


# ---------------------------------------------------------------
# Getter untuk dipakai script gameplay
# ---------------------------------------------------------------
func get_nilai(kunci: String) -> Variant:
	return nilai.get(kunci)


func kesulitan() -> int:
	return int(nilai["kesulitan"])


func kecepatan_tuning() -> float:
	return float(nilai["kecepatan_tuning"])


func getaran_kamera() -> float:
	return float(nilai["getaran_kamera"])


func efek_glitch() -> bool:
	return bool(nilai["efek_glitch"])


func getar_haptic() -> bool:
	return bool(nilai["getar_haptic"])


func ukuran_tombol() -> float:
	return float(nilai["ukuran_tombol"])


## Getar HP sebentar, hanya kalau pemain mengaktifkannya
func getar(ms: int = 60) -> void:
	if getar_haptic():
		Input.vibrate_handheld(ms)


# ---------------------------------------------------------------
# Bahasa
# ---------------------------------------------------------------
## idx: 0 = Indonesia, 1 = English. Mengubah bahasa seluruh game (tr() ikut berubah).
func set_bahasa(idx: int) -> void:
	idx = clampi(idx, 0, KODE_BAHASA.size() - 1)
	nilai["bahasa"] = idx
	TranslationServer.set_locale(KODE_BAHASA[idx])
	simpan()
	berubah.emit("bahasa")


# ---------------------------------------------------------------
# Ubah pengaturan
# ---------------------------------------------------------------
func atur(kunci: String, nilai_baru: Variant) -> void:
	nilai[kunci] = nilai_baru
	if kunci in KUNCI_GRAFIS:
		nilai["preset_grafis"] = 3  # diubah manual, jadi Kustom

	if kunci.begins_with("vol_"):
		terapkan_audio()
	if kunci in KUNCI_GRAFIS:
		terapkan_grafis()
	if kunci == "ukuran_tombol":
		terapkan_ke_scene(get_tree().current_scene)

	simpan()
	berubah.emit(kunci)


func terapkan_preset(idx: int) -> void:
	var p: Dictionary = {}
	match idx:
		0:
			p = {"resolusi_render": 1, "bayangan": false, "kualitas_bayangan": 0, "glow": false, "ssao": false, "batas_fps": 0}
		1:
			p = {"resolusi_render": 2, "bayangan": true, "kualitas_bayangan": 0, "glow": true, "ssao": false, "batas_fps": 1}
		2:
			p = {"resolusi_render": 3, "bayangan": true, "kualitas_bayangan": 1, "glow": true, "ssao": true, "batas_fps": 1}
		_:
			return  # 3 = Kustom, tidak mengubah apa-apa

	for k in p.keys():
		nilai[k] = p[k]
	nilai["preset_grafis"] = idx
	terapkan_grafis()
	simpan()
	berubah.emit("preset_grafis")


func reset_default() -> void:
	nilai = _nilai_default()
	TranslationServer.set_locale(KODE_BAHASA[int(nilai["bahasa"])])
	terapkan_audio()
	terapkan_grafis()
	simpan()
	berubah.emit("semua")


# ---------------------------------------------------------------
# Audio
# ---------------------------------------------------------------
func _pastikan_bus() -> void:
	for nama in [BUS_MUSIK, BUS_SFX]:
		if AudioServer.get_bus_index(nama) == -1:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, nama)
			AudioServer.set_bus_send(idx, "Master")


func terapkan_audio() -> void:
	_set_bus("Master", float(nilai["vol_master"]))
	_set_bus(BUS_MUSIK, float(nilai["vol_musik"]))
	_set_bus(BUS_SFX, float(nilai["vol_sfx"]))


func _set_bus(nama: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(nama)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


# ---------------------------------------------------------------
# Grafis
# ---------------------------------------------------------------
func terapkan_grafis() -> void:
	var idx_res: int = int(nilai["resolusi_render"])
	var idx_bay: int = int(nilai["kualitas_bayangan"])
	var idx_fps: int = int(nilai["batas_fps"])

	var vp: Viewport = get_viewport()
	vp.scaling_3d_scale = RESOLUSI_RENDER[idx_res]

	var ukuran: int = UKURAN_BAYANGAN[idx_bay]
	vp.positional_shadow_atlas_size = ukuran
	RenderingServer.directional_shadow_atlas_set_size(ukuran, true)

	Engine.max_fps = BATAS_FPS[idx_fps]
	terapkan_ke_scene(get_tree().current_scene)


## Terapkan bayangan, glow, SSAO, dan ukuran tombol ke scene yang sedang jalan.
## Dipanggil otomatis saat setting berubah, dan dari _ready() scene gameplay.
func terapkan_ke_scene(root: Node) -> void:
	if root == null:
		return

	var bayangan: bool = bool(nilai["bayangan"])
	var glow: bool = bool(nilai["glow"])
	var ssao: bool = bool(nilai["ssao"])

	for n in root.find_children("*", "Light3D", true, false):
		var lampu: Light3D = n as Light3D
		if lampu:
			lampu.shadow_enabled = bayangan

	for n in root.find_children("*", "WorldEnvironment", true, false):
		var we: WorldEnvironment = n as WorldEnvironment
		if we and we.environment:
			we.environment.glow_enabled = glow
			we.environment.ssao_enabled = ssao

	var skala: float = ukuran_tombol()
	for n in get_tree().get_nodes_in_group(GRUP_TOMBOL_SENTUH):
		var c: Control = n as Control
		if c:
			c.pivot_offset = c.size * 0.5
			c.scale = Vector2.ONE * skala
