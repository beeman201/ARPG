extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite = $AnimatedSprite2D

# Enum for animation states
enum AnimState { RIGHT, RIGHT_IDLE, LEFT, LEFT_IDLE, UP, UP_IDLE, DOWN, DOWN_IDLE, ATTACK }
# Enum for input mode
enum InputMode { MOUSE, CONTROLLER }
var current_anim_state: AnimState = AnimState.DOWN_IDLE
var last_direction: Vector2 = Vector2.DOWN
var aim_direction: Vector2 = Vector2.DOWN
var input_mode: InputMode = InputMode.MOUSE
var is_aiming: bool = false  # Track if actively aiming
var has_aimed: bool = false  # Track if aim input has ever been used

func _ready():
	add_to_group("player")
	# Set initial mode based on controller presence
	if Input.get_connected_joypads().size() > 0:
		input_mode = InputMode.CONTROLLER
		print("Controller detected, starting in CONTROLLER mode")
	
	#var shader_material = animated_sprite.material as ShaderMaterial
	#shader_material.set_shader_parameter("old_color", Color.RED)
	#shader_material.set_shader_parameter("new_color", Color.BLUE)

func _physics_process(delta):
	# Get movement input (left joystick or keyboard)
	var horizontaldirection = Input.get_axis("left", "right") # left = -1, right = +1
	var verticaldirection = Input.get_axis("up", "down")      # up = -1, down = +1
	var direction = Vector2(horizontaldirection, verticaldirection).normalized()
	
	# Set velocity
	velocity = direction * SPEED

	# Get aim input based on input mode
	var new_aim_direction = aim_direction  # Default to current aim_direction
	is_aiming = false  # Reset aiming state
	if input_mode == InputMode.MOUSE:
		var mouse_pos = get_global_mouse_position()
		new_aim_direction = (mouse_pos - global_position).normalized()
		is_aiming = true  # Always aiming with mouse
		has_aimed = true  # Record that aiming has occurred
	elif input_mode == InputMode.CONTROLLER:
		var aim_horizontal = Input.get_axis("aim_left", "aim_right")
		var aim_vertical = Input.get_axis("aim_up", "aim_down")
		var joystick_aim = Vector2(aim_horizontal, aim_vertical)
		if joystick_aim.length() > 0.2:  # Deadzone to prevent jitter
			new_aim_direction = joystick_aim.normalized()
			is_aiming = true  # Actively aiming with joystick
			has_aimed = true  # Record that aiming has occurred
		# If not aiming, keep new_aim_direction as current aim_direction

	# Update aim direction
	if new_aim_direction != Vector2.ZERO:
		aim_direction = new_aim_direction

	# Update last direction when moving
	if direction != Vector2.ZERO:
		last_direction = direction

	# Handle animation state
	var new_anim_state = current_anim_state
	# Prioritize aim_direction if we've ever aimed, else use last_direction
	var facing_direction = aim_direction if has_aimed else last_direction
	if direction != Vector2.ZERO:
		# Moving: use facing direction (aim if we've aimed, else movement)
		if abs(facing_direction.x) > abs(facing_direction.y):
			new_anim_state = AnimState.RIGHT if facing_direction.x > 0 else AnimState.LEFT
		else:
			new_anim_state = AnimState.DOWN if facing_direction.y > 0 else AnimState.UP
	else:
		# Idle: use facing direction (aim if we've aimed, else movement)
		if abs(facing_direction.x) > abs(facing_direction.y):
			new_anim_state = AnimState.RIGHT_IDLE if facing_direction.x > 0 else AnimState.LEFT_IDLE
		else:
			new_anim_state = AnimState.DOWN_IDLE if facing_direction.y > 0 else AnimState.UP_IDLE

	# Update animation
	if new_anim_state != current_anim_state:
		current_anim_state = new_anim_state
		match current_anim_state:
			AnimState.RIGHT:
				animated_sprite.play("right")
			AnimState.RIGHT_IDLE:
				animated_sprite.play("right_idle")
			AnimState.LEFT:
				animated_sprite.play("left")
			AnimState.LEFT_IDLE:
				animated_sprite.play("left_idle")
			AnimState.UP:
				animated_sprite.play("up")
			AnimState.UP_IDLE:
				animated_sprite.play("up_idle")
			AnimState.DOWN:
				animated_sprite.play("down")
			AnimState.DOWN_IDLE:
				animated_sprite.play("down_idle")

	# Move the character
	move_and_slide()

func _input(event):
	# Switch input mode
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.2):
		if input_mode != InputMode.CONTROLLER:
			input_mode = InputMode.CONTROLLER
			print("Switched to CONTROLLER mode")
	# Only switch to MOUSE on deliberate actions
	elif event is InputEventMouseButton or (event is InputEventKey and event.pressed):
		if input_mode != InputMode.MOUSE:
			input_mode = InputMode.MOUSE
			print("Switched to MOUSE mode")
