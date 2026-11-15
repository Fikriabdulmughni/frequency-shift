extends Node

func _ready() -> void:
	var folder: String = "res://errors/"
	var dir := DirAccess.open(folder)
	if dir == null:
		print("Folder tidak ditemukan: ", folder)
		return

	for nama in dir.get_files():
		if nama.ends_with(".import") or nama.ends_with("_ok.png"):
			continue

		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(folder + nama)
		if bytes.size() < 8:
			print("GAGAL (file kosong): ", nama)
			continue

		var img := Image.new()
		var err: int = ERR_FILE_UNRECOGNIZED
		if bytes[0] == 0xFF and bytes[1] == 0xD8:
			err = img.load_jpg_from_buffer(bytes)
		elif bytes[0] == 0x89 and bytes[1] == 0x50:
			err = img.load_png_from_buffer(bytes)

		if err != OK:
			print("GAGAL: ", nama, " (kode ", err, ")")
			continue

		var nama_baru: String = nama.get_basename() + "_ok.png"
		var simpan_err: int = img.save_png(folder + nama_baru)
		if simpan_err == OK:
			print("DISIMPAN: ", nama_baru, " ", img.get_size())
		else:
			print("GAGAL MENYIMPAN: ", nama_baru)
