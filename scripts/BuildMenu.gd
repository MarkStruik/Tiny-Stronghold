extends Control 
signal build_requested(kind) 
@export var camera: Camera3D

var current_tile: Area3D 

func open_at(tile: Area3D):
	current_tile = tile 
	if camera != null:
		var screen_pos = camera.unproject_position(tile.position)
		position = screen_pos
	visible = true 

func _on_Basic_pressed(): 
	build_requested.emit("basic") 

func _on_Slow_pressed(): 
	build_requested.emit("slow") 
	
func _on_Splash_pressed():
	build_requested.emit("splash")
