extends Node

var lives := 10 
var money := 20

func add_money(v:int): 
	money += v 
	update_ui()

func spend_money(v:int) -> bool:
	if money >= v: 
		money -= v 
		update_ui()
		return true 
	return false
	
func base_hit(dmg:int): 
	lives -= dmg 
	update_ui()
	if lives <= 0: 
		print("Game Over") 
		on_lose()
		
func restart():
	lives = 10
	money = 20
	update_ui()

var money_label: Label
var lives_label: Label
var wave_label: Label
var end_panel: Control


func bind_ui(money_l: Label, lives_l: Label, wave_l: Label, end_p: Control) -> void:
	money_label = money_l
	lives_label = lives_l
	wave_label = wave_l
	end_panel = end_p
	update_ui()

func update_ui() -> void:
	if money_label:
		money_label.text = "Money: " + str(money)
	if lives_label:
		lives_label.text = "Lives: " + str(lives)
	if wave_label:
		var spawner = get_tree().get_first_node_in_group("Spawner")
		if spawner:
			wave_label.text = "Wave " + str(spawner.current_wave + 1)

func on_win() -> void:
	_end_screen(true)

func on_lose() -> void:
	_end_screen(false)

func _end_screen(win: bool) -> void:
	if end_panel:
		end_panel.visible = true
		end_panel.get_node("VBoxContainer/Label").text = "YOU WIN" if win else "TRY AGAIN"
