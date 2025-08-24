extends Node3D 
@export var range := 8.0 
@export var fire_rate := 1.0 
@export var damage := 2.0 
@export var cost := 20 
@export var mode := "basic" # "basic"|"slow"|"splash" 
@export var color :Color
@onready var head := $Head
@onready var canon := $Head/Barel
@onready var muzzle := $Head/Barel/Muzzle 
@onready var area: Area3D = $RangeArea 
var targets: Array[Node3D] = [] 
var can_fire := true 

func _ready(): 
	area.body_entered.connect(func(b): 
		if b.is_in_group("Enemy"):
			targets.append(b)) 
	area.body_exited.connect(func(b): 
		targets.erase(b)) 
		
	if color != null: 
		canon.color = color
		canon.UpdateTint()
				
func _process(_d): 
	_cleanup_targets() 
	var t = _select_target() 
	
	if t: 
		var direction = (t.global_transform.origin - head.global_transform.origin)
		#direction.y = 0
		direction = direction.normalized()

		var angle = atan2(direction.x, direction.z)
		head.rotation.y = angle
 	
	if can_fire && targets.size() > 0: 
		_fire(t) 
		
func _fire(target): 
	if target == null: 
		return
	
	can_fire = false 
	var b = preload("res://scenes/bullets/Bullet.tscn").instantiate() 
	b.global_transform.origin = muzzle.global_transform.origin 
	
	if mode == "slow": b.set_meta("slow", true) 
	if mode == "splash": b.set_meta("splash", true) 
		
	b.setup(target, damage) 
	
	get_tree().current_scene.add_child(b) 
	await get_tree().create_timer(1.0 / fire_rate).timeout 
	can_fire = true 
		
func _select_target(): 
	if targets.is_empty(): 
		return null 
	targets = targets.filter(is_instance_valid)
	targets.sort_custom(func(a,b): return a.path_follow.progress > b.path_follow.progress) 
	return targets[0] 

func _cleanup_targets(): targets = targets.filter(is_instance_valid)
