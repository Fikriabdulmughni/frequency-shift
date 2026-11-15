extends Node3D

@export var total_objects: int = 30  # Batasi jumlahnya agar tetap ringan
@export var spread_range: Vector3 = Vector3(20.0, 5.0, 20.0)

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(total_objects):
		# 1. Buat node MeshInstance3D baru secara manual lewat kode
		var obj = MeshInstance3D.new()
		
		# 2. Buat bentuk mesh sederhana (misalnya bola kecil)
		var sphere = SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.16
		obj.mesh = sphere
		
		# 3. Tentukan posisi acak di dalam area
		var random_pos = Vector3(
			rng.randf_range(-spread_range.x, spread_range.x),
			rng.randf_range(0.2, spread_range.y),
			rng.randf_range(-spread_range.z, spread_range.z)
		)
		obj.position = random_pos
		
		# 4. Masukkan objek ke dalam scene tree agar muncul di game
		add_child(obj)
