extends Camera3D

@export var amplitudo_posisi: float = 0.015
@export var amplitudo_rotasi: float = 0.35 # derajat
@export var kecepatan: float = 0.35
@export var kehalusan: float = 4.0 # makin besar makin responsif, makin kecil makin halus

var transform_awal: Transform3D
var noise := FastNoiseLite.new()
var waktu: float = 0.0
var offset_pos := Vector3.ZERO
var offset_rot := Vector3.ZERO
var target_pos := Vector3.ZERO
var target_rot := Vector3.ZERO

func _ready() -> void:
	transform_awal = transform
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.25

func _process(delta: float) -> void:
	waktu += delta * kecepatan
	var nx := noise.get_noise_2d(waktu * 10.0, 0.0)
	var ny := noise.get_noise_2d(0.0, waktu * 10.0)

	target_pos = Vector3(nx, ny, 0.0) * amplitudo_posisi
	target_rot = Vector3(ny, nx, 0.0) * deg_to_rad(amplitudo_rotasi)

	# Lerp yang tidak bergantung pada framerate
	var w := 1.0 - exp(-kehalusan * delta)
	offset_pos = offset_pos.lerp(target_pos, w)
	offset_rot = offset_rot.lerp(target_rot, w)

	var b := Basis.from_euler(offset_rot)
	transform = Transform3D(transform_awal.basis * b, transform_awal.origin + offset_pos)
