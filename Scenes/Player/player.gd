extends CharacterBody2D

# ---- Config ----
const GRAVITY = 1200
const MOVE_SPEED = 200
const JUMP_VELOCITY_MIN = -300   # กระโดดเบาสุด
const JUMP_VELOCITY_MAX = -600   # กระโดดแรงสุด
const MAX_CHARGE_TIME = 1.0      # วินาที

# ---- State ----
var jump_charge := 0.0
var is_charging := false

func _physics_process(delta):
	# แรงโน้มถ่วง
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# การเคลื่อนที่ซ้ายขวา
	var input_dir = Input.get_axis("Move_Left", "Move_Right")
	velocity.x = input_dir * MOVE_SPEED

	# กดปุ่ม jump (เริ่มชาร์จ)
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		is_charging = true
		jump_charge = 0.0
		print("⚡ Start charging jump")

	# ค้างปุ่ม jump (เก็บ charge)
	if is_charging and Input.is_action_pressed("Jump"):
		jump_charge = clamp(jump_charge + delta / MAX_CHARGE_TIME, 0.0, 1.0)
		print("⏳ Charging... ", jump_charge)

	# ปล่อยปุ่ม jump (กระโดด)
	if is_charging and Input.is_action_just_released("Jump"):
		do_charged_jump()
		is_charging = false
		jump_charge = 0.0

	move_and_slide()

func do_charged_jump():
	# Interpolate ระหว่าง MIN และ MAX ตาม charge
	var jump_velocity = lerp(JUMP_VELOCITY_MIN, JUMP_VELOCITY_MAX, jump_charge)
	velocity.y = jump_velocity
	print("🚀 Jump! charge=", jump_charge, " | velocity.y=", velocity.y)
