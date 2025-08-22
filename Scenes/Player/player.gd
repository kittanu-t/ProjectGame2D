extends CharacterBody2D

# --- Exported tunable variables ---
@export var MOVE_SPEED: float = 200.0
@export var GRAVITY: float = 900.0
@export var CHARGE_RATE: float = 400.0
@export var MAX_JUMP_FORCE: float = 900.0
@export var MIN_JUMP_FORCE: float = 300.0
@export var AIR_CONTROL_FACTOR: float = 0.3

# --- Internal state ---
enum PlayerState { IDLE, MOVING, CHARGING, JUMPING }
var state: PlayerState = PlayerState.IDLE
var jump_charge: float = 0.0

func _physics_process(delta: float) -> void:
	# --- Apply gravity always ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match state:
		PlayerState.IDLE, PlayerState.MOVING:
			handle_movement(delta)

			# Start charging jump
			if Input.is_action_just_pressed("Jump") and is_on_floor():
				state = PlayerState.CHARGING
				jump_charge = 0.0

		PlayerState.CHARGING:
			# Keep charging while button held
			if Input.is_action_pressed("Jump"):
				jump_charge += CHARGE_RATE * delta
				jump_charge = min(jump_charge, MAX_JUMP_FORCE)
			else:
				# Release jump -> apply force
				if is_on_floor():
					velocity.y = -max(jump_charge, MIN_JUMP_FORCE)
					state = PlayerState.JUMPING
				jump_charge = 0.0

		PlayerState.JUMPING:
			handle_air_control(delta)
			if is_on_floor():
				state = PlayerState.IDLE

	move_and_slide()


func handle_movement(delta: float) -> void:
	var input_dir = Input.get_axis("Move_Left", "Move_Right")
	velocity.x = input_dir * MOVE_SPEED
	if abs(input_dir) > 0:
		state = PlayerState.MOVING
	else:
		state = PlayerState.IDLE


func handle_air_control(delta: float) -> void:
	var input_dir = Input.get_axis("Move_Left", "Move_Right")
	velocity.x = lerp(velocity.x, input_dir * MOVE_SPEED, AIR_CONTROL_FACTOR * delta)
