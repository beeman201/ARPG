extends CharacterBody2D

# Constants and enums
enum PetState { IDLE, FOLLOW }
enum AnimState { RIGHT, RIGHT_IDLE }

# Exportable properties
@export var speed: float = 200.0
@export var follow_distance: float = 120.0
@export var stop_buffer: float = 7.0
@export var lerp_weight: float = 0.1
@export var owner_id: int = 1
@export var debug: bool = true

# Node references and variables
@onready var animated_sprite = $AnimatedSprite2D
var max_health: float = 100.0
var health: float = 100.0
var pet_health_bar: ProgressBar = null
var player: Node = null
var current_state: PetState = PetState.IDLE
var current_anim_state: AnimState = AnimState.RIGHT_IDLE
var last_direction: Vector2 = Vector2.RIGHT
var is_facing_left: bool = false

# Signals
signal pet_damaged(amount: float, health: float)

func _ready():
	add_to_group("pet")
	visible = true
	animated_sprite.modulate = Color.WHITE
	animated_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	collision_layer = 1 << 2  # Layer 2 (Pet)
	collision_mask = 1 << 0   # Layer 0 (Environment)
	z_index = 1
	if debug:
		print("Pet: collision_layer=", collision_layer, ", collision_mask=", collision_mask, ", z_index=", z_index)
	_find_player()
	if not player:
		var timer = get_tree().create_timer(0.5, false)
		timer.timeout.connect(_find_player)
	else:
		if max_health > 0:
			health = max_health
			pet_damaged.emit(0, health)
			if pet_health_bar and debug:
				print("Pet health bar initialized: ", pet_health_bar.value, "/", pet_health_bar.max_value)
		if player.has_signal("level_up"):
			player.level_up.connect(_on_player_level_up)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	set_physics_process(player != null)

func _find_player():
	if multiplayer.get_unique_id() == 1 and owner_id == 1:
		player = get_tree().get_first_node_in_group("player")
	else:
		for node in get_tree().get_nodes_in_group("player"):
			if node.get_multiplayer_authority() == owner_id:
				player = node
				break
	if not player:
		push_warning("Player not found for pet ", name, " with owner_id ", owner_id)
	else:
		set_physics_process(true)
		if max_health > 0:
			health = max_health
			pet_damaged.emit(0, health)
			if pet_health_bar and debug:
				print("Pet health bar set after finding player: ", pet_health_bar.value, "/", pet_health_bar.max_value)
		if player.has_signal("level_up"):
			player.level_up.connect(_on_player_level_up)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			pet_damaged.connect(hud._on_pet_damaged)
			pet_health_bar = hud.get_node_or_null("PetHealthBar")

func _on_player_level_up(level: int, xp: float, xp_to_next: float):
	# Health set in player.gd
	if debug:
		print("Pet received level up: level=", level, ", max_health=", max_health, ", health=", health)

func _on_peer_disconnected(id: int):
	if id == owner_id:
		queue_free()

func _physics_process(_delta):
	if not player or not is_instance_valid(player):
		set_physics_process(false)
		queue_free()
		return
	var distance_to_player = global_position.distance_to(player.global_position)
	current_state = PetState.FOLLOW if distance_to_player > follow_distance + stop_buffer else PetState.IDLE
	var direction = (player.global_position - global_position).normalized()
	velocity = Vector2.ZERO if current_state == PetState.IDLE else velocity.lerp(direction * speed, lerp_weight)
	if current_state == PetState.FOLLOW and direction != Vector2.ZERO:
		last_direction = direction
	move_and_slide()
	position = position.round()
	is_facing_left = direction.x < 0 if abs(direction.x) > abs(direction.y) else last_direction.x < 0
	var new_anim_state = AnimState.RIGHT if current_state == PetState.FOLLOW else AnimState.RIGHT_IDLE
	if new_anim_state != current_anim_state:
		current_anim_state = new_anim_state
		var anim = "right" if current_anim_state == AnimState.RIGHT else "right_idle"
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)
	animated_sprite.flip_h = is_facing_left
	if debug:
		print("Pet: facing_left=", is_facing_left, ", anim=", animated_sprite.animation, ", flip_h=", animated_sprite.flip_h)

func _input(event):
	if is_multiplayer_authority() and event.is_action_pressed("ui_accept"):
		take_damage(10)

func take_damage(amount: float):
	if not is_multiplayer_authority():
		return
	health = clamp(health - amount, 0, max_health)
	Global.pet_health = health
	pet_damaged.emit(amount, health)
	if health <= 0:
		queue_free()
	if debug:
		print("Pet damaged: health=", health, "/", max_health)

func update_health_bar():
	if pet_health_bar:
		pet_health_bar.value = health
