@tool
extends EditorScript

const FOLDER := "res://adegan/"

func _run() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		push_error("Buka scene Cutscene dulu.")
		return

	var dir := DirAccess.open(FOLDER)
	if dir == null:
		push_error("Folder tidak ditemukan: " + FOLDER)
		return

	var daftar: Array[String] = []
	for nama in dir.get_files():
		if nama.ends_with(".tres"):
			daftar.append(nama)

	daftar.sort_custom(_urut_nomor)

	var arsip: Array[ArsipAdegan] = []
	for nama in daftar:
		var res := load(FOLDER + nama) as ArsipAdegan
		if res:
			arsip.append(res)
		else:
			push_warning("Gagal memuat: " + nama)

	root.set("arsip_cutscene", arsip)
	print("Selesai: %d adegan dimuat. Sekarang tekan Ctrl+S untuk menyimpan scene." % arsip.size())

func _urut_nomor(a: String, b: String) -> bool:
	return _nomor(a) < _nomor(b)

func _nomor(nama: String) -> int:
	var angka := ""
	for c in nama:
		if c.is_valid_int():
			angka += c
	return angka.to_int()
