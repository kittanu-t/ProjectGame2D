extends Camera2D

@export var room_limit_top: float = 0
@export var room_limit_bottom: float = 1920 # ขนาดห้องสูงสุด

func _process(delta):
	var player = get_node("../Player")
	var target_y = clamp(player.global_position.y, room_limit_top, room_limit_bottom)
	global_position.y = target_y
