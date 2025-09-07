extends Node

var levels := [
	"res://Levels/Level1.tscn",
	"res://Levels/Level2.tscn"
	# add more levels here...
]

var current_index := 0

func load_level_by_index(i: int) -> void:
	current_index = clamp(i, 0, levels.size() - 1)
	if Engine.is_editor_hint():
		return
	# Godot 4:
	if "change_scene_to_file" in get_tree():
		get_tree().change_scene_to_file(levels[current_index])
	else:
		# Godot 3 fallback
		get_tree().change_scene(levels[current_index])

func restart_level() -> void:
	if Engine.is_editor_hint():
		return
	# Godot 4/3 both have reload_current_scene; if it fails, fall back
	var err := get_tree().reload_current_scene()
	if err != OK:
		load_level_by_index(current_index)

func next_level() -> void:
	var next_i := current_index + 1
	if next_i < levels.size():
		load_level_by_index(next_i)
	else:
		# finished all levels; loop or go to a win screen
		load_level_by_index(0)

func check_game_state(did_win: bool) -> void:
	if did_win:
		next_level()
	else:
		restart_level()
