extends Node3D 
@onready var build_menu := $CanvasLayer/BuildMenu 

func _ready(): 
	for tile in $BuildTiles.get_children(): 
		tile.tile_clicked.connect(_on_tile_clicked)
	 
func _on_tile_clicked(tile):
	build_menu.open_at(tile)
