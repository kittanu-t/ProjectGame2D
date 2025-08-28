# WindArea.gd
extends Area2D

# --- Export variables ให้จูนค่าใน Inspector ---
@export var wind_force: Vector2 = Vector2(300, 0)
@export var blow_duration: float = 1.0   # เวลาพัด (วินาที)
@export var idle_duration: float = 2.0   # เวลาหยุด (วินาที)
@export var start_blowing: bool = false   # ถ้าตั้ง true จะเริ่มพัดทันที

@onready var particles: GPUParticles2D = $GPUParticles2D  # reference ไปยัง CPUParticles2D

# internal state
var _blowing: bool = false
var _players: Array = []   # เก็บ reference ของ player nodes ที่อยู่ใน area

func _ready() -> void:
	# เชื่อมสัญญาณ Timer (ต้องมี child Timer ชื่อ "Timer")
	$Timer.timeout.connect(_on_timer_timeout)

	# ถ้าต้องการเริ่มต้นเป็นพัด ให้กำหนด _blowing ตาม export
	_blowing = start_blowing

	# กำหนดค่า wait_time เริ่มต้น
	$Timer.wait_time = blow_duration if _blowing else idle_duration
	$Timer.start()

	# เชื่อมสัญญาณ area body_detect
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

	# update visual ตามสถานะเริ่มต้น
	_update_visuals()

func _on_body_entered(body: Node) -> void:
	# เมื่อมี body เข้ามาในพื้นที่ ให้เก็บ ถ้าเป็น Player
	if body is CharacterBody2D and body.name == "Player":
		if not _players.has(body):
			_players.append(body)

func _on_body_exited(body: Node) -> void:
	# เอาออกเมื่อออกจากพื้นที่
	if body is CharacterBody2D and body.name == "Player":
		_players.erase(body)

func _on_timer_timeout() -> void:
	# สลับสถานะ blowing/idle
	_blowing = !_blowing
	$Timer.wait_time = blow_duration if _blowing else idle_duration
	$Timer.start()

	# อัปเดต visual / particle effect
	_update_visuals()

func _physics_process(delta: float) -> void:
	if not _blowing:
		return
	for p in _players:
		if not is_instance_valid(p):
			continue
		var scaled_force := wind_force * delta
		p.call_deferred("apply_wind", scaled_force)

func _update_visuals() -> void:
	# เปิด/ปิด Particles2D ตามสถานะพัด
	if particles:
		particles.emitting = _blowing
