extends Node3D

@export var color: Color = Color(0,0,0,0)
@onready var canon = $"weapon-cannon/barrel"

func UpdateTint():
	var mat = canon.get_active_material(0)
	if mat && color != null:
		mat = mat.duplicate()
		mat.albedo_color = color
		canon.set_surface_override_material(0, mat)
