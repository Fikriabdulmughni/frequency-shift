extends ColorRect

var timer: float = 0.0
var jeda: float = 3.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	jeda = randf_range(2.0, 6.0)

func _process(delta: float) -> void:
	timer += delta
	if timer >= jeda:
		timer = 0.0
		jeda = randf_range(2.5, 7.0)
		_kedip()

func _kedip() -> void:
	var m := material as ShaderMaterial
	if not m:
		return
	var t := create_tween()
	t.tween_method(func(v: float): m.set_shader_parameter("kedip", v), 0.0, 0.25, 0.04)
	t.tween_method(func(v: float): m.set_shader_parameter("kedip", v), 0.25, 0.0, 0.18)
