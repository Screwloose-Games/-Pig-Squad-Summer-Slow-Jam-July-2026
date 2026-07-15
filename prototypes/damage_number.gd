class_name DamageNumber
extends Label
## Floating combat damage number: drifts up, fades out, frees itself.


func _ready() -> void:
	position.x += randf_range(-10.0, 10.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.3)
	tween.chain().tween_callback(queue_free)


func setup(amount: int) -> void:
	text = str(amount)
