extends Node

@export var enemy_scene := preload("res://scenes/enemies/Enemy.tscn")
var spawning := false
 
func start_demo_wave():
	if spawning:
		return 

	spawning = true 
	
	for i in 10:
		_spawn_enemy() 
		await get_tree().create_timer(0.6).timeout 
	
	spawning = false

func _spawn_enemy():
	var e = enemy_scene.instantiate()
	e.global_transform.origin = $"../Spawn".global_transform.origin
	e.add_to_group("Enemy") 
	get_tree().current_scene.add_child(e)
