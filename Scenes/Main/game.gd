# Main.gd
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var spawn_point: Marker2D = $SpawnPoint

func _ready() -> void:
	# วางผู้เล่นที่จุดเกิดเริ่มต้น
	player.global_position = spawn_point.global_position
	
	# - RE-ADDED -# เชื่อมต่อสัญญาณจาก Player เพื่อรอรับคำสั่งขยับกล้อง
	#player.connect("change_camera_pos", _on_player_change_camera_pos)

# - REMOVED -# ไม่ต้องใช้ _process อีกต่อไป
# func _process(delta: float) -> void:
#	 camera.position.y = player.global_position.y

func _on_player_change_camera_pos(new_camera_y: float) -> void:
	# - RE-ADDED -# ฟังก์ชันสำหรับขยับกล้องเมื่อได้รับสัญญาณ
	$Camera2D.position.y = new_camera_y
