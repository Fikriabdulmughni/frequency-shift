class_name TransitionSettings
extends Resource

@export_group("Warna")
@export var warna_latar: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var warna_bar_kosong: Color = Color(0.18, 0.18, 0.18, 1.0)
@export var warna_bar_isi: Color = Color(0.85, 0.85, 0.85, 1.0)
@export var warna_teks: Color = Color(0.7, 0.7, 0.7, 1.0)

@export_group("Ukuran")
@export var lebar_bar: float = 320.0
@export var tinggi_bar: float = 6.0
@export var ukuran_font: int = 18
@export var jari_jari_sudut: int = 3

@export_group("Teks")
@export var teks_memuat: String = "TRANSISI_MEMUAT"
## Jeda (ms) sebelum titik bertambah satu
@export var jeda_titik_ms: int = 350

@export_group("Animasi")
@export var durasi_fade_masuk: float = 0.3
@export var durasi_fade_keluar: float = 0.4
## Kecepatan bar mengejar progres loader
@export var kecepatan_bar: float = 120.0
