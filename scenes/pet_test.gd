extends CharacterBody2D

enum PetState { IDLE, FOLLOW, ATTACK }
enum AnimState { MOVE_RIGHT, RIGHT_IDLE }

@onready var animated_sprite = $AnimatedSprite2D
var owner_id: int = 0
var max_health: float = 100.0
var health: float = 100.0
var pet_name: String = ""
var pet_health_bar: ProgressBar = null
var speed: float = 250.0
var follow_distance: float = 35.0
var stop_buffer: float = 10.0
var lerp_weight: float = 0.1
var current_state: PetState = PetState.IDLE
var current_anim_state: AnimState = AnimState.RIGHT_IDLE
var is_facing_left: bool = false
var last_direction: Vector2 = Vector2.RIGHT
@export var debug: bool = true

signal pet_damaged(amount: float, health: float)

func _ready():
	add_to_group("pet")
	collision_layer = 1 << 3  # Layer 3: Pet
	collision_mask = 1 << 2  # Collides with Enemy
	z_index = 3  # NEW: Pet above Player
	if animated_sprite:
		animated_sprite.flip_h = is_facing_left
		if animated_sprite.sprite_frames.has_animation("right_idle"):
			animated_sprite.play("right_idle")
		else:
			push_error("Pet: Animation 'right_idle' not found!")
	else:
		push_error("Pet: AnimatedSprite2D node missing!")
	if debug:
		print("Pet: Initialized: max_health=", max_health, ", health=", health, ", name=", pet_name, ", z_index=", z_index)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		pet_health_bar = hud.get_node_or_null("PetHealthBar")
		if pet_health_bar:
			pet_health_bar.max_value = max_health
			pet_health_bar.value = health
			pet_damaged.emit(0, health)
			if debug:
				print("Pet: Health bar initialized: ", pet_health_bar.value, "/", pet_health_bar.max_value)

func _physics_process(_delta: float):
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		if debug:
			print("Pet: Player not found, freeing")
		set_physics_process(false)
		queue_free()
		return
	var distance_to_player = global_position.distance_to(player.global_position)
	if debug:
		print("Pet: Distance to player=", distance_to_player)
	var direction = (player.global_position - global_position).normalized()
	is_facing_left = direction.x < 0
	if animated_sprite:
		animated_sprite.flip_h = is_facing_left
	match current_state:
		PetState.IDLE:
			velocity = Vector2.ZERO
			_play_animation(AnimState.RIGHT_IDLE)
			if distance_to_player > follow_distance + stop_buffer:
				current_state = PetState.FOLLOW
				if debug:
					print("Pet: Switching to FOLLOW, distance=", distance_to_player)
			if debug:
				print("Pet: Idle, pos=", global_position, ", anim=", animated_sprite.animation, ", flip_h=", is_facing_left)
		PetState.FOLLOW:
			if distance_to_player > follow_distance:
				velocity = velocity.lerp(direction * speed, lerp_weight)
				_play_animation(AnimState.MOVE_RIGHT)
				if direction != Vector2.ZERO:
					last_direction = direction
				if debug:
					print("Pet: Moving, pos=", global_position, ", anim=", animated_sprite.animation, ", flip_h=", is_facing_left)
			else:
				velocity = Vector2.ZERO
				current_state = PetState.IDLE
				_play_animation(AnimState.RIGHT_IDLE)
				if debug:
					print("Pet: Switching to IDLE, distance=", distance_to_player)
			if false:  # Placeholder for ATTACK
				current_state = PetState.ATTACK
				if debug:
					print("Pet: Switching to ATTACK")
		PetState.ATTACK:
			velocity = Vector2.ZERO
			_play_animation(AnimState.RIGHT_IDLE)
			if debug:
				print("Pet: In ATTACK, pos=", global_position, ", anim=", animated_sprite.animation)
			if true:  # Placeholder exit
				current_state = PetState.FOLLOW
				if debug:
					print("Pet: Switching to FOLLOW")
	move_and_slide()
	position = position.round()

func _play_animation(anim_state: AnimState):
	var new_anim_state = anim_state
	if new_anim_state != current_anim_state:
		current_anim_state = new_anim_state
		var anim_name = "move_right" if current_anim_state == AnimState.MOVE_RIGHT else "right_idle"
		if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
			if debug:
				print("Pet: Animation changed to ", anim_name)
		else:
			push_error("Pet: Animation '", anim_name, "' not found!")

func take_damage(amount: float):
	health = clamp(health - amount, 0, max_health)
	if pet_health_bar:
		pet_health_bar.value = health
	pet_damaged.emit(amount, health)
	if health <= 0:
		if debug:
			print("Pet: Died, name=", pet_name)
		queue_free()
	else:
		if debug:
			print("Pet: Damaged, health=", health, "/", max_health)
