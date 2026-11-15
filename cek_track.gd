extends Node3D

func _ready() -> void:
	var ap := get_node("VisualMonster/Enemy/ga024_lurcher2/AnimationPlayer") as AnimationPlayer
	print("root_node: ", ap.root_node)
	print("daftar animasi: ", ap.get_animation_list())

	var anim := ap.get_animation("pose_5")
	if anim == null:
		print("pose_5 TIDAK ADA")
		return

	for i in anim.get_track_count():
		var jumlah := anim.track_get_key_count(i)
		var nilai: Array = []
		for k in jumlah:
			nilai.append(anim.track_get_key_value(i, k))
		print("TRACK ", i, " | path: ", anim.track_get_path(i), " | keys: ", jumlah, " | nilai: ", nilai)
