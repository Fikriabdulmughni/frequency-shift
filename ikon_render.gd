extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var gambar: Image = $SubViewport.get_texture().get_image()
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	gambar.save_png("res://ikon_radio.png")
	print("Ikon tersimpan di res://ikon_radio.png")
	get_tree().quit()
