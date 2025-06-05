extends Node2D

@onready var label = $Label
var text: String = ""
var move_speed: float = 50.0  # Pixels per second upward
var fade_duration: float = 2.0  # Seconds to fade out
var lifetime: float = 3.0  # Total seconds before freeing

func _ready():
	if label:
		label.text = text
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 50, lifetime).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(label, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(queue_free).set_delay(lifetime)
	else:
		push_error("FloatingText: Label node missing!")
		queue_free()

func _process(delta: float):
	if label:
		label.text = text
