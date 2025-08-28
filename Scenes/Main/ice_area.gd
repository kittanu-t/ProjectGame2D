# IceArea.gd
extends Area2D

# export ให้คุณจูนใน Inspector
@export var debug_name: String = "ice"
@export var only_affect_player: bool = true  # ถ้าต้องการให้ affect เฉพาะ node ชื่อ "Player"

func _ready() -> void:
	# เชื่อมสัญญาณ เมื่อ body เข้ามา/ออก
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	# ถ้าเป็น Player ให้บอก Player ว่าเข้า ice (ใช้ call_deferred เพื่อความปลอดภัย)
	if _is_target_player(body):
		# call_deferred เพื่อหลีกเลี่ยงการเปลี่ยน state ใน loop ฟิสิกส์ของ Area
		body.call_deferred("set_on_ice", true)
		# (optional) เล่นเสียงหรือเปิด particle: call_deferred เพื่อ safety
		if has_node("Particles2D"):
			call_deferred("_enable_particles", true)

func _on_body_exited(body: Node) -> void:
	if _is_target_player(body):
		body.call_deferred("set_on_ice", false)
		if has_node("Particles2D"):
			call_deferred("_enable_particles", false)

func _enable_particles(enable: bool) -> void:
	if has_node("Particles2D"):
		$Particles2D.emitting = enable

func _is_target_player(body: Node) -> bool:
	# ตรวจว่าเป็น CharacterBody2D และ (optionally) ชื่อ "Player"
	if body is CharacterBody2D:
		if only_affect_player:
			return body.name == "Player"
		return true
	return false
