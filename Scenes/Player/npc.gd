# NPC.gd
extends Node2D

@onready var talk_area: Area2D = $TalkArea
@export var dialogue_ui_scene: PackedScene   # ตั้งเป็น res://UI/DialogueUI.tscn ใน Inspector

# บทพูด (แก้/เพิ่มใน Inspector ได้)
@export var lines_first_visit: PackedStringArray = [
	"หวัดดีนายนะ เมาแล้วมาอยู่ที่นี้ได้ไงนั้นเหรอ ลองขึ้นไปหาคำตอบที่ด้านบนสิ!",
	"ปุ่มซ้าย/ขวา เดิน, ค้างปุ่มกระโดดเพื่อชาร์จ แล้วยกนิ้วเพื่อพุ่ง"
]
@export var lines_tips: PackedStringArray = [
	"กำแพงไม่ใช่ศัตรูเสมอไป… บางทีมันก็ช่วยดีดตัวได้นะ",
	"ถ้าตกแรงไปจะช็อค—ต้องกดกระโดดฟื้นตัว อย่าลืมล่ะ"
]
@export var lines_taunt_when_fall: PackedStringArray = [
	"เบื่อหน้าละลงมาบ่อยเกินbro",
	"พี่ชายก็กากเกิน",
	"สงสัยคิถึงกันลงมาหากันแบบนี้",
	"จอกเกินวะbro",
	"กินแต่เหล้าเลยหลอนติอ้าย"
]

@export var require_interact: bool = false      # true = ต้องกดคุย; false = เข้าแล้วคุยอัตโนมัติ
@export var interact_action: String = "ui_accept"
@export var fall_speed_threshold: float = 450.0 # ถ้าเข้ามาด้วยความเร็วลงมากกว่านี้ถือว่า “ตกแรง”
@export var cooldown_sec: float = 1.2

var _player: CharacterBody2D = null
var _cooldown_timer: float = 0.0
var _visited: bool = false
var _dialog_open: bool = false

func _ready() -> void:
	talk_area.body_entered.connect(_on_body_entered)
	talk_area.body_exited.connect(_on_body_exited)
	set_process(true)

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	# ถ้าต้องกดคุย
	if require_interact and _player and not _dialog_open and _cooldown_timer <= 0.0:
		if Input.is_action_just_pressed(interact_action):
			_start_dialog(_pick_lines())

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.name == "Player":
		_player = body
		if not require_interact and _cooldown_timer <= 0.0 and not _dialog_open:
			_start_dialog(_pick_lines())
			print("enter")

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null

# -------------------- UPDATED PICK LINES --------------------
func _pick_lines() -> PackedStringArray:
	# 1) ถ้าตกแรง "หรือ" อยู่ในสถานะ fall state → สุ่มแซว 1 บรรทัด
	var taunt_condition := false
	if _player:
		if _player.velocity.y > fall_speed_threshold:
			taunt_condition = true
		elif _is_player_fallen():
			taunt_condition = true

	if taunt_condition and lines_taunt_when_fall.size() > 0:
		return PackedStringArray([lines_taunt_when_fall[randi() % lines_taunt_when_fall.size()]])

	# 2) ครั้งแรกที่เจอ → พูดทั้งหมด (คืนทั้งอาร์เรย์)
	if not _visited:
		return lines_first_visit

	# 3) ครั้งถัดไป → ถ้า tips > 2 ให้สุ่ม 1 บรรทัด, ไม่งั้นคืนตามที่มี
	if lines_tips.size() > 2:
		return PackedStringArray([lines_tips[randi() % lines_tips.size()]])
	return lines_tips

# อ่านสถานะล้ม (fall state) จาก Player อย่างปลอดภัย แม้ _player จะพิมพ์เป็น CharacterBody2D
func _is_player_fallen() -> bool:
	if _player == null:
		return false
	var v : bool = _player.get("is_fallen")  # อ่าน property แบบ dynamic (เลี่ยง error จาก static typing)
	return v is bool and v

# -------------------- SPAWN UI --------------------
func _start_dialog(lines: PackedStringArray) -> void:
	if dialogue_ui_scene == null:
		push_warning("NPC: dialogue_ui_scene is NULL (ยังไม่ได้ตั้งใน Inspector)")
		return

	var ui: CanvasLayer = dialogue_ui_scene.instantiate()
	ui.layer = 100                           # ลอยบนสุด
	get_tree().root.add_child(ui)            # วางบน root โดยตรง
	print("NPC: spawn DialogueUI with ", lines.size(), " lines")

	_dialog_open = true
	_cooldown_timer = cooldown_sec
	_visited = true

	ui.tree_exited.connect(func ():
		_dialog_open = false
	)

	ui.call_deferred("start", lines)
