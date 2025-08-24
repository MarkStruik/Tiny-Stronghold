extends Node3D

@export var speed := 25.0
var target: Node3D
var damage := 1.0

func setup(t: Node3D, d: float) -> void:
	target = t
	damage = d

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var dir = (target.global_transform.origin - global_transform.origin).normalized()
	global_transform.origin += dir * speed * delta

	if global_transform.origin.distance_to(target.global_transform.origin) < 0.6:
		if has_meta("splash"):
			for e in get_tree().get_nodes_in_group("Enemy"):
				if is_instance_valid(e) and e.global_transform.origin.distance_to(global_transform.origin) < 2.5:
					if e.has_method("take_damage"):
						e.take_damage(damage * 0.7)
		elif has_meta("slow"):
			if target.has_method("apply_slow"):
				target.apply_slow(0.5, 1.5)
			if target.has_method("take_damage"):
				target.take_damage(damage * 0.5)
		else:
			if target.has_method("take_damage"):
				target.take_damage(damage)
		queue_free()

func _ready() -> void:
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree():
		queue_free()
