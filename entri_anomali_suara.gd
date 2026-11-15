class_name EntriAnomaliSuara
extends Resource

## Suara yang bisa dipilih untuk anomali suara
@export var stream: AudioStream
## Peluang dipilih. 1.0 normal, 0.3 lebih jarang, 0 tidak pernah dipilih
@export_range(0.0, 10.0, 0.1) var bobot: float = 1.0
## Potong suara di detik ini. 0 berarti pakai seluruh file. Wajib diisi kalau stream loop
@export var potong_di_detik: float = 0.0
@export_range(-80.0, 6.0) var volume_db: float = 0.0
@export_range(0.5, 2.0, 0.01) var pitch: float = 1.0

## Durasi suara yang benar-benar terdengar
func durasi_efektif() -> float:
	if stream == null:
		return 0.0
	var panjang := stream.get_length()
	if potong_di_detik > 0.0:
		return minf(potong_di_detik, panjang)
	return panjang

func loop_aktif() -> bool:
	if stream == null:
		return false
	if stream is AudioStreamWAV:
		return (stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED
	if "loop" in stream:
		return bool(stream.get("loop"))
	return false
