extends Node2D

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	pass
	
func _on_player_change_camera_pos(new_cam_y: float) -> void:
	$Camera2D.position.y = new_cam_y
