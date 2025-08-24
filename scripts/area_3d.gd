extends Area3D 

signal tile_clicked(tile) 
func _input_event(camera, event, pos, normal, shape_idx): 
	if event is InputEventMouseButton and \
	event.pressed and event.button_index == MOUSE_BUTTON_LEFT:tile_clicked.emit(self)
