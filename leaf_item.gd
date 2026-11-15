extends Node3D

@export var fall_speed: float = 1.2      # Kecepatan jatuh ke bawah
@export var sway_speed: float = 2.0      # Kecepatan ayunan ke kiri-kanan
@export var sway_amount: float = 1.5     # Lebar ayunan horizontal
@export var rotation_speed: float = 1.5  # Kecepatan putar daun

var time_passed: float = 0.0
var spawn_y: float = 6.0                 # Ketinggian awal daun muncul
var reset_y: float = -4.0                # Batas bawah sebelum daun di-reset ke atas
var x_center: float = 0.0                # Titik tengah sumbu X

func _ready() -> void:
	# Simpan posisi X awal sebagai titik tengah ayunan
	x_center = position.x
	# Acak waktu awal agar setiap daun tidak bergerak bersamaan
	time_passed = randf() * 50.0
	# Acak sedikit kecepatan tiap daun supaya dinamis
	fall_speed += randf_range(-0.3, 0.3)

func _process(delta: float) -> void:
	time_passed += delta
	
	# 1. Gerakan turun ke bawah secara konstan (tanpa gravitasi fisik)
	position.y -= fall_speed * delta
	
	# 2. Gerakan melayang horizontal pakai Sinus (efek tertiup angin halus)
	position.x = x_center + sin(time_passed * sway_speed) * sway_amount
	
	# 3. Efek rotasi mulus (seperti meliuk-liuk di udara)
	rotation.x = sin(time_passed * rotation_speed) * 0.7
	rotation.y += rotation_speed * delta * 0.5
	rotation.z = cos(time_passed * rotation_speed * 1.3) * 0.5
	
	# 4. Sistem Looping: Jika daun sudah sampai bawah layar, kembalikan ke atas
	if position.y < reset_y:
		respawn()

func respawn() -> void:
	position.y = spawn_y
	# Acak posisi X sedikit agar tidak muncul di jalur yang persis sama
	x_center = randf_range(-4.0, 4.0)
	position.x = x_center
	time_passed = randf() * 10.0 # Reset fase gelombang
