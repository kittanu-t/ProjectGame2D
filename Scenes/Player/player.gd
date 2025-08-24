extends CharacterBody2D

# --- CONFIG ---
@export var GRAVITY: float = 2000.0
@export var CHARGE_RATE: float = 600.0          # ความเร็วในการชาร์จ
@export var MAX_JUMP_FORCE: float = 650.0       # แรงกระโดดสูงสุด
@export var MIN_JUMP_FORCE: float = 200.0       # แรงกระโดดต่ำสุด
@export var MAX_HORIZONTAL_FORCE: float = 280.0 # ระยะกระโดดแนวนอนสูงสุด
@export var WALL_BOUNCE_FORCE: float = 280.0    # แรงดีดออกจากกำแพง
@export var WALL_BOUNCE_UP_FORCE: float = 350.0 # ดีดขึ้นเล็กน้อยตอนชนกำแพง

@export var room_height: int = 480   # ความสูงห้อง (px)

# --- SIGNAL ---
signal change_camera_pos(new_camera_y: float)

# --- STATE ---
var _current_room: int = 0
var jump_force: float = 0.0
var is_charging: bool = false
var is_jumping: bool = false
var last_direction: int = 0 # -1 = ซ้าย, 1 = ขวา
var move_speed: float = 280.0

func _ready() -> void:
	# ตั้งเริ่มต้นตามตำแหน่งตอนเริ่ม
	_current_room = int(floor(position.y / room_height))
	# ให้กล้องวางตำแหน่งตามห้องเริ่มต้น
	emit_signal("change_camera_pos", _room_center_y(_current_room))

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta


	# --- Input ---
	var input_dir := Input.get_axis("Move_Left", "Move_Right")
	if input_dir != 0:
		last_direction = sign(input_dir)

	# --- Charge Jump ---

	# เริ่มชาร์จเมื่อเพิ่งกด (just pressed) — หยุดการเคลื่อนที่ไว้ทันที
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		is_charging = true
		jump_force = 0.0                     # เริ่มสะสมจาก 0
		# ถ้ากดทิศตอนเริ่ม ให้บันทึกทิศทันที
		if input_dir != 0:
			last_direction = int(sign(input_dir))
		# หยุดแนวนอนทันทีเมื่อเริ่มชาร์จ
		velocity.x = 0.0

	# ขณะกดค้าง => เพิ่มชาร์จ และตรวจ auto-release (เมื่อเต็ม)
	elif is_charging and Input.is_action_pressed("Jump"):
		jump_force = clamp(jump_force + CHARGE_RATE * delta, 0.0, MAX_JUMP_FORCE)

		# ถ้าชาร์จเต็ม ให้ auto-release (กระโดดเอง)
		if jump_force >= MAX_JUMP_FORCE:
			_do_jump_from_force()
			is_charging = false
			is_jumping = true

	# ปล่อยปุ่มก่อนเต็ม => ปกติ release -> กระโดด
	elif is_charging and Input.is_action_just_released("Jump"):
		_do_jump_from_force()
		is_charging = false
		is_jumping = true


	# --- Normal move (เดินบนพื้น) ---
	if is_on_floor() and not is_charging:
		velocity.x = input_dir * move_speed

	# --- Wall Bounce ---
	if is_jumping and is_on_wall() and abs(velocity.x) < 10:
		velocity.x = -last_direction * WALL_BOUNCE_FORCE * 0.65
		velocity.y = -WALL_BOUNCE_UP_FORCE * 1.056 

	# --- Move ---
	move_and_slide()

	# Reset jump state
	if is_on_floor():
		is_jumping = false
		
	# ตรวจ room index หลัง movement/physics update
	var room = int(floor(position.y / room_height))
	if room != _current_room:
		_current_room = room
		emit_signal("change_camera_pos", _room_center_y(_current_room))
		
func _room_center_y(room_index: int) -> float:
	# คำนวณตำแหน่ง y ของศูนย์กลางห้อง (Camera.position.y)
	return room_index * room_height + room_height * 0.5
	
func _do_jump_from_force() -> void:
	# ปรับสเกลแกน X และ Y ให้ได้ฟีลที่คุณอยากได้
	# แกน X ให้เล็กกว่าปกติ (เช่น 0.8) และแกน Y เพิ่มขึ้นเล็กน้อย (เช่น 1.12)
	var t : float= clamp(jump_force / MAX_JUMP_FORCE, 0.0, 1.0)
	var vx : float= lerp(0.0, MAX_HORIZONTAL_FORCE * 0.8, t) * last_direction    # X ลดเหลือ 80%
	var vy : float= -max(MIN_JUMP_FORCE, jump_force) * 1.12                      # Y เพิ่ม ~12%

	velocity.x = vx
	velocity.y = vy

	# รีเซ็ตค่าชาร์จ
	jump_force = 0.0
