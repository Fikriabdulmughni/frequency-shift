class_name EfekFade
extends Resource

## Modul fade. Kosongkan slot "fade" di adegan jika tidak ingin fade.

@export var durasi_keluar: float = 1.0   ## layar menggelap
@export var durasi_jeda: float = 2.0     ## layar tetap gelap (perubahan terjadi di sini)
@export var durasi_masuk: float = 1.0    ## layar terang kembali
@export var warna: Color = Color.BLACK
