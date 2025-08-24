extends Control 
signal build_requested(kind) 
@export var camera: Camera3D
@export var BasicColor: Color
@export var SlowColor: Color
@export var SplashColor: Color

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

func _build(kind: String) -> void:
	var t = preload("res://scenes/towers/Tower.tscn").instantiate()
	
	match kind:
		"basic":
			t.mode = "basic"
			t.cost = 20
			t.damage = 5.0
			t.fire_rate = 1.5
			t.color = BasicColor
			
		"slow":
			t.mode = "slow"
			t.cost = 30
			t.damage = 1.0
			t.fire_rate = 1.3
			t.color = SlowColor
		"splash":
			t.mode = "splash"
			t.cost = 40
			t.damage = 2.0
			t.fire_rate = 1.1
			t.color = SplashColor

	if Game.spend_money(t.cost):
		t.global_transform.origin = current_tile.global_transform.origin
		get_tree().current_scene.add_child(t)
		current_tile.queue_free()
		visible = false
