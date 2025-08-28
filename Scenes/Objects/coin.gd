# Coin.gd
extends Area2D

@export var value: int = 1

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.name == "Player":
		var main = get_tree().current_scene
		if main and main.has_method("on_coin_collected"):
			# แจ้ง Main ว่าเก็บเหรียญ (deferred เพื่อความปลอดภัย)
			main.call_deferred("on_coin_collected", value)
		# ลบตัวเองแบบ deferred
		call_deferred("queue_free")
