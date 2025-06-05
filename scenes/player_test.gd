extends CharacterBody2D

const SPEED = 300.0
enum AnimState { RIGHT, IDLE }
enum InputMode { MOUSE, CONTROLLER }

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var hud_scene = preload("res://scenes/player_hud.tscn")
@onready var next_scene = preload("res://scenes/game_2_test.tscn")
@onready var attack_area: Area2D = $AttackArea

var health_bar: ProgressBar = null
var pet_health_bar: ProgressBar = null
var hud: CanvasLayer = null
@export var pet_scene: PackedScene
var pet: Node = null
var max_health: float = 100.0
var health: float = max_health
var level: int = 1
var xp: float = 0.0
var xp_to_next_level: float = 750.0
var player_name: String = ""
var damage: float = 10.0
var attack_cooldown: float = 0.5
var last_attack_time: float = 0.0
var current_anim_state: AnimState = AnimState.IDLE
var last_direction: Vector2 = Vector2.RIGHT
var aim_direction: Vector2 = Vector2.RIGHT
var input_mode: InputMode = InputMode.MOUSE
var is_aiming: bool = false
var has_aimed: bool = false
var is_facing_left: bool = false
@export var debug: bool = true
var last_scene_change_time: float = 0.0
const SCENE_CHANGE_COOLDOWN: float = 1.0

signal player_damaged(amount: float, health: float)
signal level_up(level: int, xp: float, xp_to_next: float)

func _ready():
	add_to_group("player")
	set_multiplayer_authority(multiplayer.get_unique_id())
	input_mode = InputMode.CONTROLLER if Input.get_connected_joypads().size() > 0 else InputMode.MOUSE
	collision_layer = 1 << 1  # Layer 1: Player
	collision_mask = 1 << 0 | 1 << 2  # Collides with Environment, Enemy
	z_index = 2  # NEW: Player below Pet, above Enemies
	global_position = Vector2(100, 100)
	if camera:
		camera.enabled = true
		camera.make_current()
		camera.zoom = Vector2(2.0, 2.0)
		camera.position_smoothing_enabled = false
		if debug:
			print("Player: Camera enabled at position: ", camera.global_position, ", z_index=", z_index)
	else:
		push_error("Player: Camera2D node missing!")
	if not pet_scene and Global.pet_scene:
		pet_scene = Global.pet_scene
	elif not pet_scene:
		pet_scene = Global.load_scene(Global.pet_scenes.get(Global.selected_pet, "res://scenes/pet_test.tscn"), "pet_scene", Global.selected_pet)
	sync_stats_from_global()
	if animated_sprite:
		animated_sprite.flip_h = is_facing_left
		var anim_name = "right" if current_anim_state == AnimState.RIGHT else "idle"
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
		else:
			push_error("Player: Animation '", anim_name, "' not found!")
	else:
		push_error("Player: AnimatedSprite2D node missing!")
	if is_multiplayer_authority():
		_setup_hud()
		_spawn_pet()
		var err = player_damaged.connect(Global.current_scene._on_player_damaged if Global.current_scene and Global.current_scene.has_method("_on_player_damaged") else hud._on_player_damaged)
		if err:
			push_error("Player: Failed to connect player_damaged: ", err)
		err = level_up.connect(hud.update_level_bar)
		if err:
			push_error("Player: Failed to connect level_up: ", err)
		player_damaged.emit(0, health)
		level_up.emit(level, xp, xp_to_next_level)
		hud.call_deferred("update_name_labels")
		if attack_area:
			attack_area.collision_layer = 0
			attack_area.collision_mask = 1 << 2  # Hits Enemy
			attack_area.monitoring = false
			if not attack_area.body_entered.is_connected(_on_attack_hit):
				attack_area.body_entered.connect(_on_attack_hit)
		else:
			push_error("Player: AttackArea missing!")
	if debug:
		print("Player: level=", level, ", xp=", xp, ", xp_to_next=", xp_to_next_level, ", name=", player_name)

func sync_stats_from_global():
	level = Global.player_level
	xp = Global.player_xp
	xp_to_next_level = ceil(750.0 * pow(1.15, max(0, level - 1)))
	player_name = Global.player_name
	max_health = Global.player_max_health
	health = Global.player_health
	last_direction = Global.player_last_direction
	aim_direction = Global.player_aim_direction
	is_facing_left = Global.player_is_facing_left
	has_aimed = Global.player_has_aimed

func _setup_hud():
	if hud and is_instance_valid(hud):
		return
	if not hud_scene:
		push_error("HUD scene not assigned!")
		return
	hud = hud_scene.instantiate() as CanvasLayer
	if hud:
		get_tree().root.add_child(hud)
		health_bar = hud.get_node_or_null("HealthBar")
		pet_health_bar = hud.get_node_or_null("PetHealthBar")
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = health
			if debug:
				print("Player: Player health bar: ", health_bar.value, "/", health_bar.max_value)
		if debug:
			print("Player: HUD added to scene tree, parent=", hud.get_parent().name)
	else:
		push_error("Player: Failed to instantiate HUD!")

func _spawn_pet():
	if pet and is_instance_valid(pet):
		return
	if not pet_scene:
		push_error("pet_scene not assigned in player!")
		return
	pet = pet_scene.instantiate()
	if not pet:
		push_error("Failed to instantiate pet scene!")
		return
	pet.owner_id = multiplayer.get_unique_id()
	pet.name = "Pet_" + name
	pet.max_health = Global.pet_max_health
	pet.health = Global.pet_health
	var root = get_tree().current_scene
	if root:
		root.add_child.call_deferred(pet)
		pet.call_deferred("set", "global_position", global_position + Vector2(50, 50))
		pet.call_deferred("set", "z_index", 3)  # NEW: Pet above Player
		if hud and pet.has_signal("pet_damaged"):
			if pet.pet_damaged.is_connected(hud._on_pet_damaged):
				pet.pet_damaged.disconnect(hud._on_pet_damaged)
			pet.pet_damaged.connect(hud._on_pet_damaged)
			pet.pet_health_bar = hud.get_node_or_null("PetHealthBar")
			if pet_health_bar:
				pet_health_bar.max_value = max_health
				pet.pet_damaged.emit(0, pet.health)
				if debug:
					print("Pet: Health bar initialized: ", pet_health_bar.value, "/", pet_health_bar.max_value)
	else:
		push_error("No current scene to add pet!")
		pet.queue_free()

func _exit_tree():
	if is_multiplayer_authority() and hud and is_instance_valid(hud):
		hud.queue_free()

func _physics_process(_delta: float):
	if not is_multiplayer_authority():
		return
	var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
	velocity = direction * SPEED
	var new_aim_direction = aim_direction
	is_aiming = false
	if input_mode == InputMode.MOUSE:
		new_aim_direction = (get_global_mouse_position() - global_position).normalized()
		is_aiming = true
		has_aimed = true
	elif input_mode == InputMode.CONTROLLER:
		var joystick_aim = Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
		if joystick_aim.length() > 0.2:
			new_aim_direction = joystick_aim.normalized()
			is_aiming = true
			has_aimed = true
	if new_aim_direction != Vector2.ZERO:
		aim_direction = new_aim_direction
	if direction != Vector2.ZERO:
		last_direction = direction
	var facing_direction = aim_direction if has_aimed else last_direction
	is_facing_left = facing_direction.x < 0
	var new_anim_state = AnimState.RIGHT if direction != Vector2.ZERO else AnimState.IDLE
	if new_anim_state != current_anim_state:
		current_anim_state = new_anim_state
		var anim_name = "right" if current_anim_state == AnimState.RIGHT else "idle"
		if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
	if animated_sprite:
		animated_sprite.flip_h = is_facing_left
	move_and_slide()
	if camera:
		camera.global_position = global_position

func _input(event):
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("change_scene"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_scene_change_time >= SCENE_CHANGE_COOLDOWN:
			Global.player_last_direction = last_direction
			Global.player_aim_direction = aim_direction
			Global.player_is_facing_left = is_facing_left
			Global.player_has_aimed = has_aimed
			Global.player_health = health
			Global.pet_health = pet.health if pet and is_instance_valid(pet) else Global.pet_health
			if debug:
				print("Player: Changing scene to game_2_test.tscn")
			get_tree().change_scene_to_packed(next_scene)
			last_scene_change_time = current_time
	if event.is_action_pressed("take_damage"):
		_set_max_health(max_health + 50.0)
		if debug:
			print("Player: max_health=", max_health, ", health=", health)
			if pet:
				print("Pet: max_health=", pet.max_health, ", health=", pet.health)
	if event.is_action_pressed("ui_select"):
		take_damage(10)
		if pet and is_instance_valid(pet):
			pet.take_damage(10)
	if event.is_action_pressed("ui_focus_next"):
		gain_xp(500)
	if event.is_action_pressed("attack"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_attack_time >= attack_cooldown:
			attack()
			last_attack_time = current_time

func attack():
	if attack_area:
		attack_area.monitoring = true
		attack_area.global_position = global_position + aim_direction * 20
		if debug:
			print("Player: Attacked, damage=", damage)
		await get_tree().create_timer(0.1).timeout
		attack_area.monitoring = false

func _on_attack_hit(body: Node):
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		if debug:
			print("Player: Hit enemy ", body.name, ", damage=", damage)

func _set_max_health(value: float):
	if value <= 0:
		return
	var health_ratio = health / max_health if max_health > 0 else 1.0
	max_health = value
	health = health_ratio * max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		player_damaged.emit(0, health)
	if pet and is_instance_valid(pet) and pet_health_bar:
		pet.max_health = max_health
		pet.health = health
		pet_health_bar.max_value = max_health
		pet.pet_damaged.emit(0, pet.health)
	Global.player_max_health = max_health
	Global.player_health = health
	Global.pet_max_health = max_health
	Global.pet_health = health

func take_damage(amount: float):
	if not is_multiplayer_authority():
		return
	health = clamp(health - amount, 0, max_health)
	Global.player_health = health
	player_damaged.emit(amount, health)
	if health <= 0:
		if debug:
			print("Player died: ", name)
		if Global.is_new_game_plus:
			Global.start_new_game_plus()
		else:
			get_tree().reload_current_scene()
	else:
		if debug:
			print("Player damaged: health=", health, "/", max_health)

func gain_xp(amount: float):
	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = ceil(750.0 * pow(1.15, max(0, level - 1)))
		max_health *= 1.25
		health = max_health
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = health
		if pet and is_instance_valid(pet) and pet_health_bar:
			pet.max_health = max_health
			pet.health = max_health
			pet_health_bar.max_value = max_health
			pet.pet_damaged.emit(0, pet.health)
		Global.update_player_stats(level, xp, xp_to_next_level, player_name)
		level_up.emit(level, xp, xp_to_next_level)
		player_damaged.emit(0, health)
		if debug:
			print("Player leveled up: level=", level, ", xp=", xp, ", xp_to_next=", xp_to_next_level)
	if xp < xp_to_next_level:
		Global.update_player_stats(level, xp, xp_to_next_level, player_name)
		level_up.emit(level, xp, xp_to_next_level)
		if debug:
			print("Player XP gained: xp=", xp, "/", xp_to_next_level)
