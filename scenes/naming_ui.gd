extends CanvasLayer

var player_name_input: LineEdit
var pet_name_input: LineEdit
var confirm_button: Button

func _ready():
	print("Naming UI: Entering _ready()")
	visible = true
	player_name_input = get_node_or_null("ColorRect/Panel/VBoxContainer/PlayerNameInput")
	pet_name_input = get_node_or_null("ColorRect/Panel/VBoxContainer/PetNameInput")
	confirm_button = get_node_or_null("ColorRect/Panel/VBoxContainer/ConfirmButton")
	var color_rect = get_node_or_null("ColorRect")
	if not color_rect or not player_name_input or not pet_name_input or not confirm_button:
		push_error("NamingUI: Missing nodes, creating fallback")
		_create_fallback_ui()
		return
	color_rect.set_deferred("size", Vector2(1280, 720))
	color_rect.color = Color(0, 0, 0, 0.5)
	color_rect.visible = true
	var panel = get_node_or_null("ColorRect/Panel")
	if panel:
		panel.set_deferred("position", Vector2(440, 180))
		panel.set_deferred("size", Vector2(400, 360))
	player_name_input.set_deferred("size", Vector2(300, 40))
	pet_name_input.set_deferred("size", Vector2(300, 40))
	confirm_button.set_deferred("size", Vector2(100, 40))
	player_name_input.text = Global.player_name if Global.player_name else "Player"
	pet_name_input.text = Global.pet_name if Global.pet_name else "Pet"
	confirm_button.text = "Confirm"
	confirm_button.pressed.connect(_on_confirm_pressed)
	player_name_input.grab_focus()
	print("NamingUI: Initialized with PlayerNameInput: ", player_name_input.name)

func _create_fallback_ui():
	var color_rect = ColorRect.new()
	color_rect.name = "ColorRect"
	color_rect.color = Color(0, 0, 0, 0.5)
	color_rect.set_deferred("size", Vector2(1280, 720))
	add_child(color_rect)
	var panel = Control.new()
	panel.name = "Panel"
	panel.set_deferred("position", Vector2(440, 180))
	panel.set_deferred("size", Vector2(400, 360))
	color_rect.add_child(panel)
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	panel.add_child(vbox)
	player_name_input = LineEdit.new()
	player_name_input.name = "PlayerNameInput"
	player_name_input.placeholder_text = "Player Name"
	player_name_input.set_deferred("size", Vector2(300, 40))
	vbox.add_child(player_name_input)
	pet_name_input = LineEdit.new()
	pet_name_input.name = "PetNameInput"
	pet_name_input.placeholder_text = "Pet Name"
	pet_name_input.set_deferred("size", Vector2(300, 40))
	vbox.add_child(pet_name_input)
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "Confirm"
	confirm_button.set_deferred("size", Vector2(100, 40))
	vbox.add_child(confirm_button)
	confirm_button.pressed.connect(_on_confirm_pressed)
	player_name_input.text = "Player"
	pet_name_input.text = "Pet"
	player_name_input.grab_focus()
	print("NamingUI: Fallback UI created")

func _on_confirm_pressed():
	var player_name = player_name_input.text.strip_edges()
	var pet_name = pet_name_input.text.strip_edges()
	Global.player_name = player_name if player_name else "Player"
	Global.pet_name = pet_name if pet_name else "Pet"
	print("NamingUI: Set names - Player: ", Global.player_name, ", Pet: ", Global.pet_name)
	Global.spawn_player()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_accept") and player_name_input and (player_name_input.has_focus() or pet_name_input.has_focus() or confirm_button.has_focus()):
		_on_confirm_pressed()
		print("NamingUI: Enter key pressed, confirming names")
