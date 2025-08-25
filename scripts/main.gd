# CompatTuning.gd
extends Node

@onready var money_label:= $CanvasLayer/HBoxContainer/Money
@onready var lives_label:= $CanvasLayer/HBoxContainer/Lives
@onready var wave_label:= $CanvasLayer/HBoxContainer/Wave
@onready var endpanel:= $CanvasLayer/EndPanel

func _ready() -> void:
	#ONLY FOR DEMO
	#$Spawner.start_demo_wave()
	Game.bind_ui(money_label,lives_label,wave_label,endpanel)
	
	
	
	# Only run when using the Compatibility renderer or Web
	if not (OS.has_feature("web") or RenderingServer.get_video_adapter_name().to_lower().find("compat") != -1):
		return

	# Tighten all cameras
	for cam in get_tree().get_nodes_in_group("cameras"): # or find all Camera3D
		if cam is Camera3D:
			cam.near = max(0.2, cam.near)
			cam.far = min(150.0, cam.far)

	# Boost bias on all Directional lights
	for l in get_tree().get_nodes_in_group("lights"): # or find all DirectionalLight3D
		if l is DirectionalLight3D:
			l.shadow_enabled = true
			l.shadow_max_distance = 60.0
			l.shadow_fade_start = 48.0
			l.shadow_bias = 0.35
			l.shadow_normal_bias = 3.8
			l.shadow_blur = 1.0

	# Turn off shadow casting on ground tiles by name
	var names = ["path", "ground", "tile"]
	for m in get_tree().get_nodes_in_group("MeshInstance3D"):
		pass

	# Or: walk scene and match by name
	_walk_and_tune(get_tree().get_root(), names)


func _walk_and_tune(n: Node, names: Array[String]) -> void:
	for c in n.get_children():
		_walk_and_tune(c, names)
		if c is MeshInstance3D:
			var nl = c.name.to_lower()
			for key in names:
				if nl.find(key) != -1:
					c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					break


func _on_game_restart():
	Game.restart()
	get_tree().reload_current_scene()
