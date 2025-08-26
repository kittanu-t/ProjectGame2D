# Player.gd
extends CharacterBody2D

# --- CONFIG ---
@export var GRAVITY: float = 2000.0
@export var CHARGE_RATE: float = 600.0
@export var MAX_JUMP_FORCE: float = 650.0
@export var MIN_JUMP_FORCE: float = 200.0
@export var MAX_HORIZONTAL_FORCE: float = 280.0
@export var WALL_BOUNCE_FORCE: float = 280.0
@export var WALL_BOUNCE_UP_FORCE: float = 350.0
@export var FALL_DAMAGE_HEIGHT: float = 800.0
@export var room_height: int = 480 # - RE-ADDED -# ความสูงของแต่ละช่วงกล้อง

# --- SIGNAL ---
signal change_camera_pos(new_camera_y: float) # - RE-ADDED -# สัญญาณสำหรับ Snap กล้อง

# --- STATE ---
var jump_force: float = 0.0
var last_direction: int = 1
var move_speed: float = 280.0
var is_charging: bool = false
var is_jumping: bool = false
var is_fallen: bool = false
var _fall_start_y: float = 0.0
var _has_bounced_since_airborne: bool = false
var _current_room: int = 0 # - RE-ADDED -# Index ของห้องปัจจุบัน

func _ready() -> void:
	# - RE-ADDED -# คำนวณและตั้งค่ากล้องให้อยู่ที่ห้องเริ่มต้น
	_current_room = int(floor(global_position.y / room_height))
	emit_signal("change_camera_pos", _room_center_y(_current_room))

func _physics_process(delta: float) -> void:
	# --- Fall State Logic (ยังอยู่เหมือนเดิม) ---
	if is_fallen:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("Jump"):
			is_fallen = false
		move_and_slide()
		return

	# --- Gravity (ยังอยู่เหมือนเดิม) ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if is_jumping:
			_check_fall_damage()
		is_jumping = false
		_has_bounced_since_airborne = false

	# --- Input & Charge Jump Logic (ยังอยู่เหมือนเดิม) ---
	var input_dir := Input.get_axis("Move_Left", "Move_Right")
	if input_dir != 0:
		last_direction = int(sign(input_dir))

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		is_charging = true
		jump_force = 0.0
		if input_dir != 0:
			last_direction = int(sign(input_dir))
		velocity.x = 0.0
	elif is_charging and Input.is_action_pressed("Jump"):
		jump_force = clamp(jump_force + CHARGE_RATE * delta, 0.0, MAX_JUMP_FORCE)
		if jump_force >= MAX_JUMP_FORCE:
			_do_jump()
	elif is_charging and Input.is_action_just_released("Jump"):
		_do_jump()
		
	if is_on_floor() and not is_charging:
		velocity.x = input_dir * move_speed

	# --- Wall Bounce Logic (ยังอยู่เหมือนเดิม) ---
	if is_jumping and is_on_wall() and not _has_bounced_since_airborne:
		_has_bounced_since_airborne = true
		var bounce_strength = abs(velocity.x) * 0.5 + WALL_BOUNCE_FORCE * 0.2
		velocity.x = -sign(velocity.x) * min(bounce_strength, WALL_BOUNCE_FORCE)
		velocity.y = -WALL_BOUNCE_UP_FORCE
	
	# --- Move and Fall Detection (ยังอยู่เหมือนเดิม) ---
	var was_on_floor = is_on_floor()
	move_and_slide()
	if was_on_floor and not is_on_floor():
		_fall_start_y = global_position.y

	# --- RE-ADDED: Camera Snap Logic ---
	var new_room = int(floor(global_position.y / room_height))
	if new_room != _current_room:
		_current_room = new_room
		emit_signal("change_camera_pos", _room_center_y(_current_room))

func _do_jump() -> void:
	var t: float = clamp(jump_force / MAX_JUMP_FORCE, 0.0, 1.0)
	var vx: float = lerp(0.0, MAX_HORIZONTAL_FORCE, t) * last_direction
	var vy: float = -max(MIN_JUMP_FORCE, jump_force)
	velocity.x = vx
	velocity.y = vy
	jump_force = 0.0
	is_charging = false
	is_jumping = true

func _check_fall_damage() -> void:
	var fall_distance = global_position.y - _fall_start_y
	if fall_distance >= FALL_DAMAGE_HEIGHT:
		is_fallen = true

func _room_center_y(room_index: int) -> float:
	# - RE-ADDED -# ฟังก์ชันคำนวณจุดกึ่งกลางของห้อง
	return float(room_index) * room_height + room_height * 0.5
