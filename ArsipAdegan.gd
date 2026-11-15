class_name ArsipAdegan
extends Resource

@export_category("Pengaturan Kamera")
@export var target_marker: NodePath
@export_enum("Slide", "Blink", "Zoom", "Cinematic Slide") var tipe_transisi: int = 0
@export var durasi_gerak_kamera: float = 1.5
@export var tingkat_zoom: float = 45.0
@export var durasi_zoom: float = 1.0

@export_category("Fade Layar Hitam")
@export var pakai_fade: bool = false
@export var durasi_fade_masuk: float = 1.0
@export var durasi_jeda_gelap: float = 2.0
@export var durasi_fade_keluar: float = 1.0

@export_category("Layar Hitam Penuh")
## Menutupi seluruh adegan termasuk vignet. Hanya teks yang tetap terlihat.
@export var layar_hitam_penuh: bool = false

@export_category("Auto Lanjut")
## Pindah otomatis ke adegan berikutnya setelah teks selesai diketik.
@export var auto_lanjut: bool = false
## Detik menunggu setelah teks selesai sebelum pindah otomatis.
@export var jeda_auto_lanjut: float = 2.0

@export_category("Pengaturan Posisi Objek")
@export var atur_posisi_objek_manual: bool = false
@export var koordinat_tujuan_objek: Vector3 = Vector3.ZERO
@export var durasi_transisi_objek: float = 1.0
@export var target_objek_node: NodePath
@export_enum("Diabaikan", "Pindah Posisi (Tween)", "Teleport Instan", "Diam / Tetap", "Sembunyi (Hide)", "Tampilkan (Show)") var aksi_objek: int = 0

@export_category("Rotasi Objek")
## Memakai Target Objek Node di atas. Rotasi dalam derajat (global).
@export var atur_rotasi_objek: bool = false
@export var rotasi_tujuan_objek: Vector3 = Vector3.ZERO

@export_category("Pengaturan Narasi")
@export_multiline var teks_narasi: String = ""
@export var warna_teks: Color = Color.WHITE
## Klik saat teks sedang diketik diabaikan. Teks harus selesai dulu sebelum bisa lanjut.
@export var tunggu_teks_selesai: bool = false

@export_category("Pengaturan Efek & Animasi")
@export var aktifkan_getaran: bool = false
@export var kekuatan_getaran: float = 0.1

@export var anim_player_1: NodePath
@export_enum("Diabaikan", "Putar (Play)", "Berhenti (Stop)") var aksi_animasi_1: int = 0
@export var nama_animasi_1: String = ""

@export var anim_player_2: NodePath
@export_enum("Diabaikan", "Putar (Play)", "Berhenti (Stop)") var aksi_animasi_2: int = 0
@export var nama_animasi_2: String = ""

@export_category("Pengaturan Filter Audio (Muffle)")
@export_enum("Diabaikan", "Teredam Mulus (Tween)", "Teredam Instan (Blink)", "Jelas / Normal") var aksi_filter_audio: int = 0
@export var durasi_transisi_filter: float = 1.0

@export_category("Kurva Audio")
## Bentuk transisi volume untuk semua slot audio di adegan ini.
@export_enum("Linear", "Cubic", "Sine") var kurva_audio: int = 1

@export_category("Pengaturan Audio 1")
@export var audio_player_1: NodePath
@export_enum("Diabaikan", "Putar Baru", "Lanjutkan/Resume", "Pause", "Stop") var aksi_audio_1: int = 0
@export var file_suara_1: AudioStream = null
@export var volume_db_1: float = 0.0
## Detik volume naik dari senyap. 0 = langsung.
@export var fade_masuk_1: float = 0.0
## Detik volume turun ke senyap sebelum berhenti. 0 = langsung.
@export var fade_keluar_1: float = 0.0
## Detik awal audio yang diputar. 0 = dari awal.
@export var mulai_potong_1: float = 0.0
## Detik akhir audio. 0 = sampai habis.
@export var akhir_potong_1: float = 0.0
## Hanya untuk Putar Baru. Mengulang dari Mulai Potong sampai Akhir Potong.
@export var loop_audio_1: bool = false

@export_category("Pengaturan Audio 2")
@export var audio_player_2: NodePath
@export_enum("Diabaikan", "Putar Baru", "Lanjutkan/Resume", "Pause", "Stop") var aksi_audio_2: int = 0
@export var file_suara_2: AudioStream = null
@export var volume_db_2: float = 0.0
@export var fade_masuk_2: float = 0.0
@export var fade_keluar_2: float = 0.0
@export var mulai_potong_2: float = 0.0
@export var akhir_potong_2: float = 0.0
@export var loop_audio_2: bool = false

@export_category("Pengaturan Audio 3")
@export var audio_player_3: NodePath
@export_enum("Diabaikan", "Putar Baru", "Lanjutkan/Resume", "Pause", "Stop") var aksi_audio_3: int = 0
@export var file_suara_3: AudioStream = null
@export var volume_db_3: float = 0.0
@export var fade_masuk_3: float = 0.0
@export var fade_keluar_3: float = 0.0
@export var mulai_potong_3: float = 0.0
@export var akhir_potong_3: float = 0.0
@export var loop_audio_3: bool = false
