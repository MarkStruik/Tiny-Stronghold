extends Node3D
@export var occupied := false

func place_tower(scene: PackedScene) -> bool:
	if occupied: return false
	var t = scene.instantiate()
	t.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(t)
	occupied = true
	return true
