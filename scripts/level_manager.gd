extends Node3D

func load_level(scene_path: String) -> void:
	get_tree().change_scene(scene_path)
