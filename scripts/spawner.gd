extends Node

@export var enemy_scene := preload("res://scenes/enemies/Enemy.tscn")
var spawning := false
 
func start_demo_wave():
	#$CanvasLayer/Button.visible = false
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

var ENEMY_PRESET = {
	"basic": {"hp": 10, "speed": 4.0, "reward": 5, "dmg": 1},
	"fast":  {"hp": 7,  "speed": 7.0, "reward": 6, "dmg": 1},
	"tank":  {"hp": 18, "speed": 2.8, "reward": 8, "dmg": 2},
}

var waves = [
	{"seq": [{"t": "basic", "n": 6, "gap": 0.6}], "delay": 3},
	{"seq": [{"t": "basic", "n": 4, "gap": 0.5}, {"t": "fast", "n": 4, "gap": 0.4}], "delay": 4},
	{"seq": [{"t": "tank", "n": 3, "gap": 1.0}, {"t": "fast", "n": 6, "gap": 0.35}], "delay": 5},
	{"seq": [{"t": "basic", "n": 8, "gap": 0.4}, {"t": "tank", "n": 4, "gap": 0.9}], "delay": 4},
	{"seq": [{"t": "fast", "n": 10, "gap": 0.35}], "delay": 4},
	{"seq": [{"t": "tank", "n": 6, "gap": 0.8}, {"t": "fast", "n": 8, "gap": 0.35}], "delay": 5},
]

var current_wave := 0
var running := false
var spawn_point := $"../Spawn"

func _spawn_enemy(kind: String = "basic") -> void:
	var enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
	if not enemy_scene:
		push_error("Enemy scene not found!")
		return

	var e = enemy_scene.instantiate()
	
	# Get stats from ENEMY_PRESET
	var p = ENEMY_PRESET.get(kind, ENEMY_PRESET["basic"])
	e.max_hp = p["hp"]
	e.speed = p["speed"]
	e.reward = p["reward"]
	e.damage_to_base = p["dmg"]

	# Position enemy at spawn
	if spawn_point:
		e.global_transform.origin = spawn_point.global_transform.origin
	else:
		push_error("Spawn point not found!")

	e.add_to_group("Enemy")
	get_tree().current_scene.add_child(e)

func start_next_wave() -> void:
	if running or current_wave >= waves.size():
		return

	running = true
	var w = waves[current_wave]

	for part in w["seq"]:
		for i in range(part["n"]):
			_spawn_enemy(part["t"])
			await get_tree().create_timer(part["gap"]).timeout

	await get_tree().create_timer(w["delay"]).timeout
	current_wave += 1
	running = false

	if current_wave == waves.size():
		await get_tree().create_timer(2.0).timeout
		if get_tree().get_nodes_in_group("Enemy").is_empty():
			Game.on_win()
