# Main.gd
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $camera2d
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var goal_area: Area2D = $GoalArea
@onready var bgm_player: AudioStreamPlayer = $bgm_player
@onready var sfx_player: AudioStreamPlayer = $sfx_player

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

	# ตั้งกล้องตามห้องเริ่มต้น
	var room_index := int(floor(player.global_position.y / player.room_height))
	camera.position.y = float(room_index) * player.room_height + player.room_height * 0.5

	# เชื่อมสัญญาณที่ใช้งานจริง
	#player.connect("change_camera_pos", Callable(self, "_on_player_change_camera_pos"))
	#goal_area.body_entered.connect(Callable(self, "_on_goal_entered"))
	player.connect("sfx_play", Callable(self, "_on_player_sfx"))  # <-- เพิ่มบรรทัดนี้

	# เริ่มจับเวลาและ BGM เริ่มต้น
	start_game_timer()
	_switch_bgm_by_room(room_index)

func start_game_timer() -> void:
	elapsed_time = 0.0
	timer_running = true

func stop_game_timer() -> void:
	timer_running = false

func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta

func _on_player_change_camera_pos(new_camera_y: float) -> void:
	camera.position.y = new_camera_y
	var room_index := int(floor(new_camera_y / player.room_height))
	_switch_bgm_by_room(room_index)

# ------------------ BGM switching ------------------
func _switch_bgm_by_room(room_index: int) -> void:
	var streams: Array[AudioStream] = [
		bgm_room0, bgm_room1, bgm_room2, bgm_room3, bgm_room4, bgm_room5, bgm_room6
	]
	if streams.is_empty():
		return

	# map room_index (อาจติดลบ) -> ดัชนีเพลงแบบสมมาตรรอบ 0
	# room >= 0 : idx = room
	# room <  0 : idx = -room - 1   (เช่น -1->0, -2->1, -3->2, ...)
	var idx: int = room_index if room_index >= 0 else (-room_index - 0) # <— คงตามไฟล์ที่ให้มา
	idx = clamp(idx, 0, streams.size() - 1)

	var desired: AudioStream = streams[idx]
	if desired and bgm_player.stream != desired:
		bgm_player.stream = desired
		bgm_player.play()

# ------------------ SFX ------------------
func _on_player_sfx(_name: String) -> void:
	match _name:
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
		if best < 0.0 or elapsed_time < best:
			_save_best_time(elapsed_time)
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
