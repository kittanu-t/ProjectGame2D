# Player.gd
extends CharacterBody2D

# --- (ส่วน Config, Signal, State เหมือนเดิมทุกประการ) ---
@export var GRAVITY: float = 2000.0
@export var CHARGE_RATE: float = 600.0
@export var MAX_JUMP_FORCE: float = 650.0
@export var MIN_JUMP_FORCE: float = 300.0
@export var MAX_HORIZONTAL_FORCE: float = 360
@export var WALL_BOUNCE_FORCE: float = 350.0
@export var WALL_BOUNCE_UP_FORCE: float = 350.0
@export var FALL_DAMAGE_HEIGHT: float = 490
@export var room_height: int = 480

# --- ICE tuning (export เพื่อจูนใน Inspector) ---
@export var ICE_ACCEL: float = 2
@export var ICE_FRICTION_DECAY: float = 0.1


signal change_camera_pos(new_camera_y: float)
signal sfx_play(name: String)  # <-- เพิ่ม signal สำหรับให้ Main เล่น SFX

var jump_force: float = 0.0
var last_direction: int = 1
var move_speed: float = 150.0
var is_charging: bool = false
var is_jumping: bool = false
var is_fallen: bool = false
var _fall_start_y: float = 0.0
var _has_bounced_since_airborne: bool = false
var _current_room: int = 0
var _was_on_floor: bool = true # เริ่มต้นให้เป็น true

# ICE / WIND state
var _on_ice: bool = false
var _accum_wind: Vector2 = Vector2.ZERO

func _ready() -> void:
	await get_tree().process_frame
	_current_room = int(floor(global_position.y / room_height))
	emit_signal("change_camera_pos", _room_center_y(_current_room))

func _physics_process(delta: float) -> void:
	# --- Fall State Logic (เหมือนเดิม) ---
	if is_fallen:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("Jump"):
			is_fallen = false
			$AnimatedSprite2D.play("idle")
		move_and_slide()
		return

	# --- Gravity ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- Input & Charge Jump Logic (เหมือนเดิม) ---
	var input_dir := Input.get_axis("Move_Left", "Move_Right")
	if input_dir != 0:
		last_direction = int(sign(input_dir))

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		is_charging = true
		jump_force = 0.0
		# แจ้งให้เล่นเสียงเริ่มชาร์จ
		emit_signal("sfx_play", "charge_start")
		if input_dir != 0:
			last_direction = int(sign(input_dir))
		velocity.x = 0.0
	elif is_charging and Input.is_action_pressed("Jump"):
		jump_force = clamp(jump_force + CHARGE_RATE * delta, 0.0, MAX_JUMP_FORCE)
		if jump_force >= MAX_JUMP_FORCE:
			_do_jump()
	elif is_charging and Input.is_action_just_released("Jump"):
		_do_jump()
		
	# --- Movement on floor (รองรับ ice) ---
	if is_on_floor() and not is_charging:
		if _on_ice:
			# ลื่น: ค่อยๆ เลื่อนไปหาค่า target (lerp) และค่อยๆ หยุดเมื่อไม่มี input
			var target := input_dir * move_speed
			velocity.x = lerp(velocity.x, target, clamp(ICE_ACCEL * delta, 0.0, 1.0))
			if input_dir == 0:
				velocity.x = lerp(velocity.x, 0.0, clamp(ICE_FRICTION_DECAY * delta, 0.0, 1.0))
		else:
			velocity.x = input_dir * move_speed

	# --- Wall Bounce Logic (fallback เมื่อ velocity.x == 0) ---
	if is_jumping and is_on_wall() and not _has_bounced_since_airborne:
		_has_bounced_since_airborne = true
		var horiz := velocity.x
		if abs(horiz) < 1.0:
			horiz = last_direction * move_speed
		var bounce_strength : float = abs(horiz) * 0.5 + WALL_BOUNCE_FORCE * 0.2
		var dir : float = -sign(horiz)
		if dir == 0:
			dir = -last_direction
		velocity.x = dir * min(bounce_strength, WALL_BOUNCE_FORCE) * 1.15
		velocity.y = -WALL_BOUNCE_UP_FORCE
		# แจ้งให้เล่นเสียงเด้งผนัง
		emit_signal("sfx_play", "wall_bounce")
	
	# --- Apply accumulated wind BEFORE move_and_slide ---
	if _accum_wind != Vector2.ZERO:
		velocity += _accum_wind
		_accum_wind = Vector2.ZERO

	# --- Move ---
	_was_on_floor = is_on_floor()
	move_and_slide()
	
	# --- หลัง move_and_slide: ตรวจการตก/ลงพื้น ---
	var is_currently_on_floor = is_on_floor()
	if _was_on_floor and not is_currently_on_floor:
		_fall_start_y = global_position.y
	if not _was_on_floor and is_currently_on_floor:
		_check_fall_damage()
		is_jumping = false
		_has_bounced_since_airborne = false

	# --- Camera Snap Logic ---
	var new_room = int(floor(global_position.y / room_height))
	if new_room != _current_room:
		_current_room = new_room
		emit_signal("change_camera_pos", _room_center_y(_current_room))

# --- (ฟังก์ชัน _do_jump, _check_fall_damage, _room_center_y เหมือนเดิม แต่เพิ่ม emit sfx) ---
func _do_jump() -> void:
	var t: float = clamp(jump_force / MAX_JUMP_FORCE, 0.0, 1.0)
	var vx: float = lerp(0.0, MAX_HORIZONTAL_FORCE, t) * last_direction
	var vy: float = -max(MIN_JUMP_FORCE, jump_force)
	velocity.x = vx
	velocity.y = vy
	jump_force = 0.0
	is_charging = false
	is_jumping = true
	# แจ้งให้เล่นเสียงกระโดด
	emit_signal("sfx_play", "jump")

func _check_fall_damage() -> void:
	var fall_distance = global_position.y - _fall_start_y
	if fall_distance >= FALL_DAMAGE_HEIGHT:
		is_fallen = true
		$AnimatedSprite2D.play("fall")
		# แจ้งให้เล่นเสียงตก (fall state)
		emit_signal("sfx_play", "fall")

func _room_center_y(room_index: int) -> float:
	return float(room_index) * room_height + room_height * 0.5

# --- Methods for external Areas (Ice / Wind) ---
func set_on_ice(value: bool) -> void:
	_on_ice = value

func apply_wind(force: Vector2) -> void:
	_accum_wind += force
