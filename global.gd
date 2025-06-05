extends Node

@export var player_scene: PackedScene
@export var pet_scene: PackedScene
var player: Node = null
var selected_class: String = "warrior"
var selected_pet: String = "wolf"

var player_level: int = 1
var player_xp: float = 0.0
var player_xp_to_next: float = 750.0
var player_max_health: float = 100.0
var player_health: float = 100.0
var pet_max_health: float = 100.0
var pet_health: float = 100.0
var player_name: String = ""
var pet_name: String = ""
var player_last_direction: Vector2 = Vector2.RIGHT
var player_aim_direction: Vector2 = Vector2.RIGHT
var player_is_facing_left: bool = false
var player_has_aimed: bool = false
var current_scene: Node = null
var is_new_game_plus: bool = false

var class_scenes: Dictionary = {
	"warrior": "res://scenes/player_test.tscn",
	"mage": "res://scenes/player_test.tscn",
	"archer": "res://scenes/player_test.tscn"
}
var pet_scenes: Dictionary = {
	"wolf": "res://scenes/pet_test.tscn",
	"fox": "res://scenes/pet_test.tscn"
}
var enemy_scenes: Dictionary = {
	"blob": "res://scenes/Enemy.tscn"
}

func _ready():
	print("Global: Starting _ready()")
	player_xp_to_next = ceil(750.0 * pow(1.15, max(0, player_level - 1)))
	current_scene = get_tree().current_scene
	
	# Load default scenes
	player_scene = load_scene(class_scenes.get(selected_class, "res://scenes/player_test.tscn"), "player_scene", selected_class)
	pet_scene = load_scene(pet_scenes.get(selected_pet, "res://scenes/pet_test.tscn"), "pet_scene", selected_pet)
	
	# Load main scene if none exists
	if not current_scene:
		var main_scene = load_scene("res://scenes/game.tscn", "main_scene")
		if main_scene:
			var instance = main_scene.instantiate()
			get_tree().root.add_child.call_deferred(instance)
			current_scene = instance
			print("Global: Loaded main scene: res://scenes/game.tscn")
	
	# Connect node_added
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
		print("Global: Connected node_added signal")
	
	# Load naming UI if names are not set
	if not player_name or not pet_name:
		var naming_ui_scene = load_scene("res://scenes/naming_ui.tscn", "naming_ui")
		if naming_ui_scene:
			var naming_ui = naming_ui_scene.instantiate()
			get_tree().root.add_child.call_deferred(naming_ui)
			print("Global: Added naming_ui.tscn to scene tree")
		else:
			_fallback_spawn()
	else:
		spawn_player()
		print("Global: Names already set, spawning player")

func load_scene(path: String, scene_type: String, context: String = "") -> PackedScene:
	if ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		if scene:
			print("Global: Loaded ", scene_type, ": ", path, " ", context)
			return scene
		else:
			push_error("Global: Failed to load ", scene_type, ": ", path)
	else:
		push_error("Global: ", scene_type, " not found: ", path)
	return null

func _fallback_spawn():
	player_name = "Player"
	pet_name = "Wolf"
	spawn_player()
	print("Global: Fallback - Set default names and spawned player")

func spawn_player():
	if player and is_instance_valid(player):
		print("Global: Player already exists, skipping spawn")
		return
	if not player_scene:
		player_scene = load_scene(class_scenes.get(selected_class, "res://scenes/player_test.tscn"), "player_scene", selected_class)
	if not pet_scene:
		pet_scene = load_scene(pet_scenes.get(selected_pet, "res://scenes/pet_test.tscn"), "pet_scene", selected_pet)
	if not player_scene:
		return
	player = player_scene.instantiate()
	if player:
		player.set("pet_scene", pet_scene)
		player.set("player_name", player_name)
		# NEW: Reset health on spawn
		player_health = player_max_health
		pet_health = pet_max_health
		if not current_scene:
			var main_scene = load_scene("res://scenes/game.tscn", "main_scene")
			if main_scene:
				current_scene = main_scene.instantiate()
				get_tree().root.add_child.call_deferred(current_scene)
				get_tree().current_scene = current_scene
				print("Global: Loaded main scene: res://scenes/game.tscn")
			else:
				return
		current_scene.add_child.call_deferred(player)
		player.call_deferred("set", "global_position", Vector2(100, 100))
		player.call_deferred("set", "is_facing_left", player_is_facing_left)
		player.call_deferred("set", "has_aimed", player_has_aimed)
		spawn_enemies()
		print("Global: Player spawned at (100, 100) with name: ", player_name, ", class: ", selected_class)
	else:
		push_error("Global: Failed to instantiate player_scene!")

func spawn_enemies():
	var enemy_scene = load_scene(enemy_scenes.get("blob", "res://scenes/Enemy.tscn"), "enemy_scene", "blob")
	if not enemy_scene:
		return
	var num_enemies = randi_range(2, 5)
	for i in num_enemies:
		var enemy = enemy_scene.instantiate()
		current_scene.add_child.call_deferred(enemy)
		# NEW: Ensure enemies spawn further away
		var spawn_pos = Vector2(100 + randf_range(150, 300) * (-1 if randi() % 2 == 0 else 1), 
							   100 + randf_range(150, 300) * (-1 if randi() % 2 == 0 else 1))
		enemy.call_deferred("set", "global_position", spawn_pos)
		if i == 0:
			print("Global: Spawned enemy at ", spawn_pos)

func _on_node_added(node: Node):
	if node is Node2D and node == get_tree().current_scene and (!player or not is_instance_valid(player)):
		if player_name and pet_name:
			current_scene = node
			spawn_player()
			print("Global: Spawning player due to new scene: ", node.name)

func update_player_stats(p_level: int, p_xp: float, p_xp_to_next: float, p_name: String):
	player_level = p_level
	player_xp = p_xp
	player_xp_to_next = p_xp_to_next
	player_name = p_name

func start_new_game_plus():
	is_new_game_plus = true
	player_level = 1
	player_xp = 0.0
	player_xp_to_next = 750.0
	player_health = player_max_health
	pet_health = pet_max_health
	var main_scene = load_scene("res://scenes/game.tscn", "main_scene")
	if main_scene:
		get_tree().change_scene_to_packed(main_scene)
		print("Global: Started NG+")
