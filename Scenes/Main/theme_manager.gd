# ThemeManager.gd
extends Node

var themes = ["res://scenes/ForestTheme.tscn", "res://scenes/CastleTheme.tscn"]
var current_theme_index := 0
var current_theme: Node = null

func load_theme(index: int):
	if current_theme:
		current_theme.queue_free()
	var theme_scene = load(themes[index]).instantiate()
	add_child(theme_scene)
	current_theme = theme_scene
	current_theme_index = index
