extends Node

var lives := 10 
var money := 0

func add_money(v:int): 
	money += v 
	_update_ui()

func spend_money(v:int) -> bool:
	if money >= v: 
		money -= v 
		_update_ui()
		return true 
	return false
	
func base_hit(dmg:int): 
	lives -= dmg 
	_update_ui()
	if lives <= 0: 
		print("Game Over") 

func _update_ui():
	print("Lives:", lives, " Money:", money)
