@tool
extends EditorScript

func _run() -> void:
	var root = get_editor_interface().get_edited_scene_root()
	if root == null or root.get("arsip_cutscene") == null:
		print("Buka scene Cutscene dulu, lalu jalankan lagi.")
		return

	var arsip = root.get("arsip_cutscene")
	DirAccess.make_dir_recursive_absolute("res://adegan")

	var jumlah := 0
	for i in arsip.size():
		var adegan = arsip[i]
		if adegan == null:
			continue
		# Adegan yang sudah berupa file dilewati
		if adegan.resource_path != "" and not adegan.resource_path.contains("::"):
			continue

		var path := "res://adegan/adegan_%03d.tres" % i
		ResourceSaver.save(adegan, path)
		arsip[i] = load(path)
		jumlah += 1

	root.set("arsip_cutscene", arsip)
	print("Selesai: %d adegan dipindah ke res://adegan/" % jumlah)
