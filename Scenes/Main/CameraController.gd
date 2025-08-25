# CameraController.gd
extends Camera2D

@export var room_size := Vector2(480, 270)
var current_room := Vector2.ZERO

func _process(delta):
	var player = get_node("../Player")
	var room_x = floor(player.global_position.x / room_size.x)
	var room_y = floor(player.global_position.y / room_size.y)
	var new_room = Vector2(room_x, room_y)

	if new_room != current_room:
		current_room = new_room
		global_position = current_room * room_size + room_size/2
