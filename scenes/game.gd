extends Node2D

func _ready():
	var player_name_edit = $NamingUI/ColorRect/Panel/VboxContainer/PlayerNameInput
	var pet_name_edit = $NamingUI/ColorRect/Panel/VboxContainer/PetNameInput
	var submit_button = $NamingUI/ColorRect/Panel/VboxContainer/ConfirmButton
	
	if submit_button and player_name_edit and pet_name_edit:
		submit_button.pressed.connect(func():
			var player_name = player_name_edit.text.strip_edges()
			var pet_name = pet_name_edit.text.strip_edges()
			Global.player_name = player_name if player_name else "Player"
			Global.pet_name = pet_name if pet_name else "Pet"
			print("Game: Naming UI button pressed - Player: ", Global.player_name, ", Pet: ", Global.pet_name)
			$NamingUI.queue_free()
			Global.spawn_player()
		)
		print("Game: Connected naming UI button")
	else:
		push_error("Game: UI nodes missing")
		Global.player_name = "Player"
		Global.pet_name = "Pet"
		Global.spawn_player()
