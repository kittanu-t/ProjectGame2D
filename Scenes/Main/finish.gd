# Finish.gd
extends Control

@onready var time_label: Label = $TimeLabel
@onready var best_label: Label = $BestLabel
@onready var coins_label: Label = $CoinsLabel

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		var last := float(cfg.get_value("records", "last_time", -1.0))
		var best := float(cfg.get_value("records", "best_time", -1.0))
		var last_coins := int(cfg.get_value("records", "last_coins", 0))
		if last > 0:
			time_label.text = "Time: " + _format_time(last)
		else:
			time_label.text = "Time: —"
		if best > 0:
			best_label.text = "Best: " + _format_time(best)
		else:
			best_label.text = "Best: —"
		coins_label.text = "Coins: " + str(last_coins)
	else:
		time_label.text = "Time: —"
		best_label.text = "Best: —"
		coins_label.text = "Coins: 0"

func _on_btn_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main/menu.tscn")

func _on_btn_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main/game.tscn")

func _format_time(t: float) -> String:
	var mins = int(t / 60)
	var secs = int(t) % 60
	var ms = int((t - int(t)) * 1000)
	return str(mins).lpad(2, '0') + ":" + str(secs).lpad(2, '0') + "." + str(ms).lpad(3, '0')
