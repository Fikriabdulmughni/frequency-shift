extends Node

func _ready() -> void:
	TranslationServer.set_locale("id")
	print("ID: ", tr("CUT_000"))
	TranslationServer.set_locale("en")
	print("EN: ", tr("CUT_000"))
