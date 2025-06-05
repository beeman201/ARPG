extends CharacterBody2D

func _ready():
	add_to_group("player")
	set_multiplayer_authority(2) # Simulate second player
	print("DummyPlayer ready, multiplayer ID: ", get_multiplayer_authority())
