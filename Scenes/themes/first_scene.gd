extends Node2D

signal theme_boundary_reached(direction: String) # "up" | "down"

@export var room_height: int = 480       # ความสูงต่อ 1 snap
@export var total_rooms: int = 3         # รวมแล้วความสูง = room_height * total_rooms

@onready var room: Node2D = $Room
@onready var spawn_bottom: Node2D = $Room/Spawn_From_Bottom
@onready var spawn_top: Node2D    = $Room/Spawn_From_Top
@onready var exit_top: Area2D     = $Room/ExitTop
@onready var exit_bottom: Area2D  = $Room/ExitBottom

func _ready() -> void:
	# เชื่อมสัญญาณ Trigger
	exit_top.body_entered.connect(_on_exit_top_entered)
	exit_bottom.body_entered.connect(_on_exit_bottom_entered)

	# ตรวจว่า collider ตั้งถูกฝั่งหรือยัง (ตำแหน่งตาม world ของ Room)
	# - ให้ ExitTop วางไว้ "เหนือ" ห้องเล็กน้อย
	# - ให้ ExitBottom วางไว้ "ใต้" ห้องเล็กน้อย
	# ปกติแนะนำตั้งใน Editor ให้เสร็จ แต่ถ้าอยากบังคับด้วยโค้ด:
	# _auto_place_triggers()

# ---------- API ให้ Main เรียกใช้ ----------

func place_player(player: CharacterBody2D, entry: String) -> void:
	# entry: "start" | "from_top" | "from_bottom"
	match entry:
		"from_top":
			if is_instance_valid(spawn_top): player.global_position = spawn_top.global_position
		"from_bottom":
			if is_instance_valid(spawn_bottom): player.global_position = spawn_bottom.global_position
		_:
			# เริ่มเกมครั้งแรก: ใช้ spawn_bottom เป็นค่าเริ่มต้น (หรือแล้วแต่ดีไซน์)
			if is_instance_valid(spawn_bottom):
				player.global_position = spawn_bottom.global_position
	# reset ความเร็ว
	player.velocity = Vector2.ZERO

func clamp_camera_y(target_y: float) -> float:
	var min_center := _room_center_y(0)
	var max_center := _room_center_y(total_rooms - 1)
	return clampf(target_y, min_center, max_center)

func room_center_of_y(world_y: float) -> float:
	var idx := int(floor(world_y / room_height))
	return _room_center_y(idx)

# ---------- Trigger events ----------

func _on_exit_top_entered(body: Node) -> void:
	if body is CharacterBody2D and body.name == "Player":
		emit_signal("theme_boundary_reached", "up")

func _on_exit_bottom_entered(body: Node) -> void:
	if body is CharacterBody2D and body.name == "Player":
		emit_signal("theme_boundary_reached", "down")

# ---------- Helpers ----------

func _room_center_y(idx: int) -> float:
	return float(idx) * room_height + room_height * 0.5

func _auto_place_triggers() -> void:
	# ใช้เมื่อต้องการจัดตำแหน่ง ExitTop/ExitBottom ด้วยสคริปต์
	var top_y := -12.0                  # เหนือห้องเล็กน้อย
	var bottom_y := room_height * total_rooms + 12.0
	$Room/ExitTop.global_position.y = room.global_position.y + top_y
	$Room/ExitBottom.global_position.y = room.global_position.y + bottom_y
