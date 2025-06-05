extends CharacterBody2D

enum EnemyType { BLOB }
enum State { PATROL, CHASE, ATTACK, DEAD }

@export var enemy_type: EnemyType = EnemyType.BLOB
@export var debug: bool = true
@onready var attack_area = $AttackArea
@onready var health_bar = $HealthDisplay/HealthBar
@onready var name_label = $HealthDisplay/NameLabel
@onready var animated_sprite = $AnimatedSprite2D
var floating_text_scene = preload("res://scenes/floating_text.tscn")

var level: int = 1
var max_health: float = 10.0
var health: float = 10.0
var damage: float = 3.0
var speed: float = 100.0
var patrol_radius: float = 50.0
var chase_distance: float = 100.0
var attack_distance: float = 20.0
var attack_cooldown: float = 1.5
var patrol_center: Vector2
var patrol_angle: float = 0.0
var state: State = State.PATROL
var last_attack_time: float = 0.0
var is_facing_left: bool = false
var last_flip_state: bool = false

func _ready():
	add_to_group("enemy")
	collision_layer = 1 << 2  # Layer 2: Enemy
	collision_mask = 1 << 1 | 1 << 3  # Collides with Player, Pet
	z_index = 1  # NEW: Enemies below Player
	level = randi_range(1, 3)
	if Global.is_new_game_plus:
		var player_level = Global.player_level if Global.player_level > 0 else 1
		level = clamp(randi_range(player_level - 2, player_level + 2), 1, 100)
	var base_player_health = 100.0 * pow(1.25, max(0, level - 1))
	max_health = base_player_health * 0.15
	if Global.is_new_game_plus:
		max_health *= 1.5
	health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.size = Vector2(30, 5)
		var style = StyleBoxFlat.new()
		style.bg_color = Color.RED
		health_bar.add_theme_stylebox_override("fill", style)
	else:
		push_error("Enemy: HealthBar missing!")
	if name_label:
		name_label.text = "Annoying Blob Lv" + str(level)
		name_label.size = Vector2(60, 10)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_constant_override("outline_size", 2)
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	else:
		push_error("Enemy: NameLabel missing!")
	if attack_area:
		attack_area.collision_layer = 1 << 2
		attack_area.collision_mask = 1 << 1 | 1 << 3
	else:
		push_error("Enemy: AttackArea missing!")
	patrol_center = global_position
	if animated_sprite:
		animated_sprite.play("walk")
		animated_sprite.animation_looped.connect(_on_animation_looped)
		animated_sprite.flip_h = is_facing_left
	else:
		push_error("Enemy: AnimatedSprite2D missing!")
	if debug:
		print("Enemy: Initialized Annoying Blob, level=", level, ", health=", health, ", pos=", global_position, ", z_index=", z_index)

func _physics_process(delta: float):
	if state == State.DEAD:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
	var player_distance = global_position.distance_to(player.global_position)
	is_facing_left = (player.global_position.x - global_position.x) < 0
	if animated_sprite:
		animated_sprite.flip_h = is_facing_left
		if debug and is_facing_left != last_flip_state:
			print("Enemy: Flipped, is_facing_left=", is_facing_left)
			last_flip_state = is_facing_left
	match state:
		State.PATROL:
			patrol_angle += delta * 1.0
			var offset = Vector2(cos(patrol_angle), sin(patrol_angle)) * patrol_radius
			var target_pos = patrol_center + offset
			velocity = (target_pos - global_position).normalized() * speed * 0.5
			if animated_sprite:
				animated_sprite.play("walk")
			if player_distance < chase_distance:
				state = State.CHASE
				if debug:
					print("Enemy: Switching to CHASE, player_distance=", player_distance)
		State.CHASE:
			velocity = (player.global_position - global_position).normalized() * speed
			if animated_sprite:
				animated_sprite.play("walk")
			if player_distance < attack_distance:
				velocity = Vector2.ZERO
				state = State.ATTACK
				if debug:
					print("Enemy: Switching to ATTACK, player_distance=", player_distance)
			elif player_distance > chase_distance * 1.2:
				state = State.PATROL
				if debug:
					print("Enemy: Switching to PATROL, player_distance=", player_distance)
		State.ATTACK:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_attack_time >= attack_cooldown:
				if animated_sprite:
					animated_sprite.play("attack_right")
				attack(player)
				last_attack_time = current_time
				if debug:
					print("Enemy: Attack executed, cooldown reset, time=", current_time)
			if player_distance > attack_distance * 1.2:
				state = State.CHASE
				if debug:
					print("Enemy: Switching to CHASE, player_distance=", player_distance)
	move_and_slide()

func attack(target: Node):
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	target.take_damage(damage + 0.5 * (level - 1))
	if debug:
		print("Enemy: Attacked ", target.name, ", damage=", damage + 0.5 * (level - 1))

func take_damage(amount: float):
	if state == State.DEAD:
		return
	health = clamp(health - amount, 0, max_health)
	if health_bar:
		health_bar.value = health
	else:
		push_error("Enemy: HealthBar not found during take_damage!")
	if animated_sprite:
		animated_sprite.play("damage_right")
	if health <= 0:
		state = State.DEAD
		set_physics_process(false)
		collision_layer = 0
		attack_area.collision_layer = 0
		if animated_sprite:
			animated_sprite.play("dead")
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player) and player.has_method("gain_xp"):
			var xp_drop = 50.0 + 10.0 * (level - 1)
			player.gain_xp(xp_drop)
			if debug:
				print("Enemy: Awarded ", xp_drop, " XP to player")
			var text_instance = floating_text_scene.instantiate()
			text_instance.text = "+" + str(xp_drop) + " XP"
			text_instance.global_position = global_position
			get_tree().current_scene.add_child(text_instance)
			if debug:
				print("Enemy: Floating text spawned: ", text_instance.text, " at ", text_instance.global_position)
		if debug:
			print("Enemy: Died, name=", name_label.text)
	else:
		if debug:
			print("Enemy: Damaged, health=", health, "/", max_health)

func _on_animation_looped():
	if animated_sprite.animation == "dead" and state == State.DEAD:
		queue_free()
		if debug:
			print("Enemy: Freed after dead animation, name=", name_label.text)
