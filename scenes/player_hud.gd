extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var pet_health_bar: ProgressBar = $PetHealthBar
@onready var level_bar: ProgressBar = $LevelBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var pet_health_label: Label = $PetHealthBar/PetHealthLabel
@onready var level_label: Label = $LevelBar/LevelLabel
@onready var player_name_label: Label = $PlayerNameLabel
@onready var pet_name_label: Label = $PetNameLabel

func _ready():
	add_to_group("hud")
	layer = 0
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Initialize health bar
	if health_bar:
		health_bar.max_value = Global.player_max_health if Global.player_max_health > 0 else 100.0
		health_bar.value = Global.player_health if Global.player_health > 0 else 100.0
		health_bar.size = Vector2(200, 20)
		health_bar.position = Vector2(10, 10)
		health_bar.show_percentage = false
		health_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var player_style = StyleBoxFlat.new()
		player_style.bg_color = Color.RED
		player_style.border_width_left = 3
		player_style.border_width_right = 3
		player_style.border_width_top = 3
		player_style.border_width_bottom = 3
		player_style.border_color = Color.BLACK
		health_bar.add_theme_stylebox_override("fill", player_style)
	else:
		push_error("HUD: HealthBar missing!")
	
	# Initialize pet health bar
	if pet_health_bar:
		pet_health_bar.max_value = Global.pet_max_health if Global.pet_max_health > 0 else 100.0
		pet_health_bar.value = Global.pet_health if Global.pet_health > 0 else 100.0
		pet_health_bar.size = Vector2(200, 20)
		pet_health_bar.position = Vector2(viewport_size.x - 210, 10)
		pet_health_bar.show_percentage = false
		pet_health_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var pet_style = StyleBoxFlat.new()
		pet_style.bg_color = Color.GREEN
		pet_style.border_width_left = 3
		pet_style.border_width_right = 3
		pet_style.border_width_top = 3
		pet_style.border_width_bottom = 3
		pet_style.border_color = Color.BLACK
		pet_health_bar.add_theme_stylebox_override("fill", pet_style)
	else:
		push_error("HUD: PetHealthBar missing!")
	
	# Initialize level bar
	if level_bar:
		level_bar.max_value = Global.player_xp_to_next if Global.player_xp_to_next > 0 else 750.0
		level_bar.value = Global.player_xp
		level_bar.size = Vector2(350, 35)
		level_bar.position = Vector2((viewport_size.x - 350) / 2, viewport_size.y - 45)
		level_bar.show_percentage = false
		level_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var level_bg = StyleBoxFlat.new()
		level_bg.bg_color = Color.BLACK
		level_bg.border_width_left = 5
		level_bg.border_width_right = 5
		level_bg.border_width_top = 5
		level_bg.border_width_bottom = 5
		level_bg.border_color = Color.BLACK
		level_bar.add_theme_stylebox_override("background", level_bg)
		var level_fill = StyleBoxFlat.new()
		level_fill.bg_color = Color.YELLOW_GREEN
		level_bar.add_theme_stylebox_override("fill", level_fill)
	else:
		push_error("HUD: LevelBar missing!")
	
	# Create missing labels
	if not health_label and health_bar:
		health_label = Label.new()
		health_label.name = "HealthLabel"
		health_bar.add_child(health_label)
	if not pet_health_label and pet_health_bar:
		pet_health_label = Label.new()
		pet_health_label.name = "PetHealthLabel"
		pet_health_bar.add_child(pet_health_label)
	if not level_label and level_bar:
		level_label = Label.new()
		level_label.name = "LevelLabel"
		level_bar.add_child(level_label)
	
	# Configure labels
	for label in [health_label, pet_health_label, level_label]:
		if label:
			label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.clip_text = true
			label.add_theme_font_size_override("font_size", 16 if label == health_label or label == pet_health_label else 18)
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 3)
			label.position = Vector2(0, 0)
			label.size = Vector2(200, 20) if label == health_label or label == pet_health_label else Vector2(350, 35)
	
	for label in [player_name_label, pet_name_label]:
		if label:
			label.add_theme_font_size_override("font_size", 14)
			label.add_theme_color_override("font_color", Color.WHITE)
	
	# Initial updates
	_update_health_label()
	_update_pet_health_label()
	update_level_bar(Global.player_level, Global.player_xp, Global.player_xp_to_next)
	update_name_labels()

func _update_health_label():
	if health_bar and health_label:
		health_label.text = "%d/%d" % [health_bar.value, health_bar.max_value]

func _update_pet_health_label():
	if pet_health_bar and pet_health_label:
		pet_health_label.text = "%d/%d" % [pet_health_bar.value, pet_health_bar.max_value]

func update_level_bar(level: int, xp: float, xp_to_next: float):
	if level_bar and level_label:
		level_bar.max_value = xp_to_next
		level_bar.value = xp
		level_label.text = "Level %d (%d/%d)" % [level, xp, xp_to_next]

func update_name_labels():
	if player_name_label and health_bar:
		player_name_label.text = Global.player_name.capitalize() if Global.player_name else "Player"
		player_name_label.position = health_bar.position + Vector2((health_bar.size.x - player_name_label.size.x) / 2, 30)
	if pet_name_label and pet_health_bar:
		pet_name_label.text = Global.pet_name.capitalize() if Global.pet_name else "Wolf"
		pet_name_label.position = pet_health_bar.position + Vector2((pet_health_bar.size.x - pet_name_label.size.x) / 2, 30)

func _on_player_damaged(_amount: float, health: float):
	if health_bar:
		health_bar.value = health
		_update_health_label()

func _on_pet_damaged(_amount: float, health: float):
	if pet_health_bar:
		pet_health_bar.value = health
		_update_pet_health_label()
