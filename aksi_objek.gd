class_name AksiObjek
extends Resource

## Satu aksi untuk satu objek. Tambahkan beberapa di array "aksi_objek" untuk banyak objek.

@export var target: NodePath
@export_enum("Pindah (Tween)", "Teleport", "Sembunyi", "Tampilkan") var aksi: int = 1

@export_group("Yang Diubah")
@export var ubah_posisi: bool = false
@export var posisi: Vector3 = Vector3.ZERO          ## global
@export var ubah_rotasi: bool = false
@export var rotasi_derajat: Vector3 = Vector3.ZERO  ## global, dalam derajat
@export var ubah_skala: bool = false
@export var skala: Vector3 = Vector3.ONE            ## lokal

@export_group("Tween")
@export var durasi: float = 1.0
