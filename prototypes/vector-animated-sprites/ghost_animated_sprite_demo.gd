extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_1:
			sprite.play("idle")
		KEY_2:
			sprite.play("move")
		KEY_3:
			sprite.play("dodge")
		KEY_0:
			sprite.stop()


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "dodge":
		sprite.play("idle")
