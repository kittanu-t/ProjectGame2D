# Menu.gd
extends Control

@onready var items := $VBoxContainer.get_children()
@onready var best_label: Label = $VBoxContainer/BestTime
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var idx: int = 0

@export var sound_move: AudioStream
@export var sound_confirm: AudioStream

func _ready() -> void:
	_update_selection()
	_show_best_time()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu_up"):
		idx = (idx - 1) % items.size()
		_update_selection()
		_play_move()
	elif Input.is_action_just_pressed("menu_down"):
		idx = (idx + 1) % items.size()
		_update_selection()
		_play_move()
	elif Input.is_action_just_pressed("menu_select"):
		_play_confirm()
		_execute_current()

func _update_selection() -> void:
	for i in items.size():
		var lbl: Label = items[i]
		lbl.modulate = Color(1,1,1,1) if i == idx else Color(0.6,0.6,0.6,1)

func _execute_current() -> void:
	var text : String = items[idx].text
	if text == "Start":
		# ไปที่ Main scene และ timer จะเริ่มใน Main._ready()
		get_tree().change_scene_to_file("res://Scenes/Main/game.tscn")
	elif text == "Best Time":
		# อาจจะโชว์ tooltip หรือ update best_label (already shown)
		_show_best_time()
	elif text == "Exit":
		get_tree().quit()

func _play_move() -> void:
	if sound_move:
		sfx_player.stream = sound_move
		sfx_player.play()

func _play_confirm() -> void:
	if sound_confirm:
		sfx_player.stream = sound_confirm
		sfx_player.play()

func _show_best_time() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		var best := float(cfg.get_value("records", "best_time", -1.0))
		if best > 0:
			best_label.text = "Best: " + _format_time(best)
			return
	best_label.text = "Best: —"

func _format_time(t: float) -> String:
	var mins = int(t / 60)
	var secs = int(t) % 60
	var ms = int((t - int(t)) * 1000)
	
	# Corrected lines using lpad()
	return str(mins).lpad(2, '0') + ":" + str(secs).lpad(2, '0') + "." + str(ms).lpad(3, '0')
