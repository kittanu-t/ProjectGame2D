# Main.gd (DEBUG VERSION)
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $camera2d
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var goal_area: Area2D = $GoalArea
@onready var bgm_player: AudioStreamPlayer = $bgm_player
@onready var sfx_player: AudioStreamPlayer = $sfx_player

# --- DEBUG toggles ---
@export var DEBUG_BGM: bool = true                 # เปิด log ระบบ BGM
@export var DEBUG_BGM_POLL: bool = false           # โพลล์ room ทุกเฟรมแล้วเรียกสลับ BGM (ใช้เพื่อเทสแม้ยังไม่ต่อสัญญาณ)
var __dbg_last_room: int = -999999

# --- BGM / SFX resources ---
@export var bgm_room0: AudioStream
@export var bgm_room1: AudioStream
@export var bgm_room2: AudioStream
@export var bgm_room3: AudioStream
@export var bgm_room4: AudioStream
@export var bgm_room5: AudioStream
@export var bgm_room6: AudioStream

@export var sfx_charge_start: AudioStream
@export var sfx_jump: AudioStream
@export var sfx_wall_bounce: AudioStream
@export var sfx_fall: AudioStream
@export var sfx_menu_move: AudioStream
@export var sfx_menu_confirm: AudioStream
@export var sfx_coin: AudioStream

# Timer / score
var elapsed_time: float = 0.0
var timer_running: bool = false

# Coins
var coins_collected: int = 0

func _ready() -> void:
	# วางผู้เล่นที่จุดเกิดเริ่มต้น
	player.global_position = spawn_point.global_position

	# Initial camera snap (คำนวนจากตำแหน่งผู้เล่นหลังวางที่ SpawnPoint)
	var room_index := int(floor(player.global_position.y / player.room_height))
	camera.position.y = float(room_index) * player.room_height + player.room_height * 0.5

	if DEBUG_BGM:
		print("[BGM] _ready(): spawn_room=", room_index, " player_y=", player.global_position.y, " room_h=", player.room_height)
		# แจ้งเตือนถ้ายังไม่เชื่อมสัญญาณ change_camera_pos (จะทำให้ BGM ไม่สลับตอนย้ายห้อง)
		if not player.is_connected("change_camera_pos", Callable(self, "_on_player_change_camera_pos")):
			print("[BGM][WARN] player.change_camera_pos NOT connected -> _on_player_change_camera_pos (BGM จะไม่สลับเมื่อย้ายห้อง)")
		print(_dbg_streams_status())

	# เชื่อมต่อสัญญาณจาก Player (ของเดิมคุณคอมเมนต์ไว้)
	# player.connect("change_camera_pos", Callable(self, "_on_player_change_camera_pos"))

	# เชื่อมต่อ GoalArea (ของเดิมคุณคอมเมนต์ไว้)
	# goal_area.body_entered.connect(Callable(self, "_on_goal_entered"))

	# เริ่มจับเวลาเมื่อ scene พร้อมเล่นเลย
	start_game_timer()

	# start initial bgm based on spawn room
	_switch_bgm_by_room(room_index)
	__dbg_last_room = room_index

func start_game_timer() -> void:
	elapsed_time = 0.0
	timer_running = true

func stop_game_timer() -> void:
	timer_running = false

func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta

	# โหมดโพลล์เพื่อ debug (ไม่ต้องพึ่ง signal)
	if DEBUG_BGM_POLL:
		var room_index := int(floor(player.global_position.y / player.room_height))
		if room_index != __dbg_last_room:
			if DEBUG_BGM:
				print("[BGM][POLL] room changed -> ", room_index, " (from ", __dbg_last_room, ") y=", player.global_position.y)
			__dbg_last_room = room_index
			_switch_bgm_by_room(room_index)

func _on_player_change_camera_pos(new_camera_y: float) -> void:
	camera.position.y = new_camera_y
	var room_index := int(floor(new_camera_y / player.room_height))
	if DEBUG_BGM:
		print("[BGM] _on_player_change_camera_pos: new_cam_y=", new_camera_y, " -> room=", room_index)
	_switch_bgm_by_room(room_index)

# ------------------ DEBUGGED: pick among 7 BGM by room index ------------------
func _switch_bgm_by_room(room_index: int) -> void:
	var streams: Array[AudioStream] = [
		bgm_room0, bgm_room1, bgm_room2, bgm_room3, bgm_room4, bgm_room5, bgm_room6
	]
	if streams.is_empty():
		if DEBUG_BGM:
			print("[BGM][ERR] No streams array (empty)!")
		return

	var idx: int = clamp(room_index, 0, streams.size() - 1)
	var desired: AudioStream = streams[idx]

	if DEBUG_BGM:
		print("[BGM] switch request: room=", room_index, " -> idx=", idx,
			  " desired=", _dbg_stream_label(desired),
			  " current=", _dbg_stream_label(bgm_player.stream))

	if desired == null:
		if DEBUG_BGM:
			print("[BGM][WARN] Desired stream is NULL at idx=", idx, " (ยังไม่ได้ตั้งค่าใน Inspector?)")
		return

	# เปลี่ยนเฉพาะเมื่อแตกต่างจริง
	if bgm_player.stream != desired:
		bgm_player.stream = desired
		bgm_player.play()
		if DEBUG_BGM:
			print("[BGM] now playing: ", _dbg_stream_label(bgm_player.stream))
	else:
		if DEBUG_BGM:
			print("[BGM] already playing desired stream; no change")

# Debug helpers ---------------------------------------------------------------
func _dbg_stream_label(s: AudioStream) -> String:
	if s == null:
		return "null"
	# Resource มี resource_path เมื่อเป็นไฟล์ที่ import เข้าโครงการ
	if s.resource_path != "":
		return s.resource_path
	# ถ้าไม่มี path ลองใช้ชื่อ class เป็น label
	return "[" + s.get_class() + "]"

func _dbg_streams_status() -> String:
	var arr := [
		"bgm_room0=" + _dbg_stream_label(bgm_room0),
		"bgm_room1=" + _dbg_stream_label(bgm_room1),
		"bgm_room2=" + _dbg_stream_label(bgm_room2),
		"bgm_room3=" + _dbg_stream_label(bgm_room3),
		"bgm_room4=" + _dbg_stream_label(bgm_room4),
		"bgm_room5=" + _dbg_stream_label(bgm_room5),
		"bgm_room6=" + _dbg_stream_label(bgm_room6),
	]
	return "[BGM] streams: " + ", ".join(arr)
# -----------------------------------------------------------------------------


# ------------------ SFX ------------------
func _on_player_sfx(name: String) -> void:
	match name:
		"charge_start":
			_play_sfx(sfx_charge_start)
		"jump":
			_play_sfx(sfx_jump)
		"wall_bounce":
			_play_sfx(sfx_wall_bounce)
		"fall":
			_play_sfx(sfx_fall)
		_:
			pass

func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

# ------------------ Goal reached ------------------
func _on_goal_entered(body: Node) -> void:
	if body == player and timer_running:
		stop_game_timer()
		var best := _load_best_time()
		var is_new_record := false
		if best < 0.0 or elapsed_time < best:
			_save_best_time(elapsed_time)
			is_new_record = true
		_save_last_time(elapsed_time)
		_save_last_coins(coins_collected)
		call_deferred("_go_to_finish_scene")

func _go_to_finish_scene() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main/finish.tscn")

# ------------------ Coins ------------------
func on_coin_collected(amount: int = 1) -> void:
	coins_collected += amount
	_play_sfx(sfx_coin)

# ------------------ Save / Load ------------------
func _save_best_time(time_sec: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg")
	cfg.set_value("records", "best_time", time_sec)
	cfg.save("user://save.cfg")

func _load_best_time() -> float:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		return float(cfg.get_value("records", "best_time", -1.0))
	return -1.0

func _save_last_time(time_sec: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg")
	cfg.set_value("records", "last_time", time_sec)
	cfg.save("user://save.cfg")

func _load_last_time() -> float:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		return float(cfg.get_value("records", "last_time", -1.0))
	return -1.0

func _save_last_coins(n:int) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg")
	cfg.set_value("records", "last_coins", n)
	cfg.save("user://save.cfg")
