extends ColorRect

@onready var mat = material
var ripple_time := 0.0

func _process(delta):
	ripple_time += delta
	mat.set_shader_parameter("ripple_time", ripple_time)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var uv = event.position / size
		mat.set_shader_parameter("ripple_center", uv)
		ripple_time = 0.0
