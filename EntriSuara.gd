class_name EntriSuara
extends Resource

@export var nama: String = "Suara"
@export var stream: AudioStream

@export_group("Waktu di Timeline")
## Jika aktif, Detik Mulai dihitung dari saat glitch muncul, bukan dari awal animasi
@export var mulai_saat_glitch: bool = false
## Detik saat suara dibunyikan (dari awal animasi, atau dari saat glitch jika opsi di atas aktif)
@export var detik_mulai: float = 0.0
## Detik saat suara dihentikan. 0 = biarkan sampai habis
@export var detik_berhenti: float = 0.0

@export_group("Potongan dari File Audio")
## Detik di dalam file tempat suara mulai diputar. Isi dengan detik saat bunyinya mulai
@export var mulai_di_file: float = 0.0
## Detik di dalam file tempat suara dihentikan. 0 = sampai habis
@export var selesai_di_file: float = 0.0

@export_group("Volume & Nada")
@export var volume_db: float = 0.0
@export_range(0.5, 2.0, 0.01) var pitch: float = 1.0

@export_group("Fade")
@export var fade_masuk: float = 0.0
@export var fade_keluar: float = 0.2

@export_group("Perilaku")
## Ulangi suara setelah selesai (hanya untuk stream yang TIDAK di-loop di import)
@export var ulang: bool = false
## Tetap dibunyikan walaupun pemain melewati animasi
@export var ikut_saat_skip: bool = false
