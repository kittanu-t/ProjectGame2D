# NPC.gd
extends Node2D

@onready var talk_area: Area2D = $TalkArea
@export var dialogue_ui_scene: PackedScene   # ตั้งเป็น res://UI/DialogueUI.tscn ใน Inspector

# บทพูด (แก้/เพิ่มใน Inspector ได้)
@export var lines_first_visit: PackedStringArray = [
	"ยินดีต้อนรับสู่หอคอย... อย่ามั่นใจเกินไปล่ะ",
	"ปุ่มซ้าย/ขวา เดิน, ค้างปุ่มกระโดดเพื่อชาร์จ แล้วยกนิ้วเพื่อพุ่ง"
]
@export var lines_tips: PackedStringArray = [
	"กำแพงไม่ใช่ศัตรูเสมอไป… บางทีมันก็ช่วยดีดตัวได้นะ",
	"ถ้าตกแรงไปจะช็อค—ต้องกดกระโดดฟื้นตัว อย่าลืมล่ะ"
]
@export var lines_taunt_when_fall: PackedStringArray = [
	"โอ้ย… ยังไม่ชินแรงโน้มถ่วงสินะ!",
	"ลงทางเดิมเร็วจัง ขึ้นใหม่ไหวไหม?"
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

func _pick_lines() -> PackedStringArray:
	if _player:
		# ถ้าเข้ามาด้วยความเร็วลง (y+) สูง → แซว/เตือน
		if _player.velocity.y > fall_speed_threshold:
			return lines_taunt_when_fall
	# ครั้งแรกที่เจอ → พูดสอน
	if not _visited:
		return lines_first_visit
	# ปกติ → ให้ tips ทั่วไป (สุ่ม 1–2 บรรทัด)
	if lines_tips.size() <= 2:
		return lines_tips
	else:
		var out := PackedStringArray()
		out.append(lines_tips[randi() % lines_tips.size()])
		out.append(lines_tips[randi() % lines_tips.size()])
		return out

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
