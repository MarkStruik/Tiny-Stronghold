extends CharacterBody3D

@export var max_hp := 10 
@export var speed := 3.0 
@export var reward := 5
@export var damage_to_base := 1 
@export var type := "basic"

@export var basic_skin :PackedScene
@export var fast_skin :PackedScene
@export var tank_skin :PackedScene
@export var boss_skin :PackedScene

var hp := 0 
var path_follow: PathFollow3D 
var slow_factor := 1.0 

func _ready(): 
	hp = max_hp 
	var template: PathFollow3D = get_tree().get_first_node_in_group("PathTemplate")
	path_follow = template.duplicate() 
	template.get_parent().add_child(path_follow) 
	
	match type:
		"basic":
			var enemy = basic_skin.instantiate()
			enemy.scale = Vector3(2,2,2)
			$".".add_child(enemy)
		"fast":
			var enemy = fast_skin.instantiate()
			enemy.scale = Vector3(1,1,1)
			$".".add_child(enemy)
		"tank":
			var enemy = tank_skin.instantiate()
			enemy.scale = Vector3(2.5,2.5,2.5)
			$".".add_child(enemy)
		"boss":
			var enemy = boss_skin.instantiate()
			enemy.scale = Vector3(3,3,3)
			$".".add_child(enemy)

func _physics_process(delta): 
	path_follow.progress += speed * slow_factor * delta 
	global_transform.origin = path_follow.global_transform.origin 
	
	if path_follow.progress_ratio >= 0.95:
		Game.base_hit(damage_to_base) 
		queue_free() 

func take_damage(amount: float): 
	hp -= amount 
	print( "Enemy took damage! Health left: ", hp)
	if hp <= 0:
		Game.add_money(reward) 
		queue_free() 
		
func apply_slow(multiplier: float, duration: float): 
	slow_factor = clamp(multiplier, 0.2, 1.0)
	await get_tree().create_timer(duration).timeout 
	slow_factor = 1.0
