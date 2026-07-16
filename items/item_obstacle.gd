class_name ItemObstacle
extends StaticBody2D

## Drop this under anything items should land on and slide off — a gladiator, a prop.
## The host needs no script and knows nothing about items.
##
## Deliberately kept off any animated node: mount it on the host's root, not under a
## Visuals branch, so placeholder animation never drives physics.
##
## The collision_mask stays EMPTY, and that is load-bearing rather than an oversight.
## Godot registers a collision if *either* body scans the other
## (A.layer & B.mask || B.layer & A.mask). If this body scanned the item layer, items
## could never opt out of hitting it, and Item.set_carried()'s drag opt-out would
## silently do nothing. Items scan us; we never scan back.

## Radius of the body items collide with. A circle so items shed off instead of
## balancing on top. Note this inherits the host's scale.
@export var radius: float = 48.0:
	set(value):
		radius = value
		_apply_radius()

@onready var _collision_shape: CollisionShape2D = %CollisionShape2D


func _ready() -> void:
	_apply_radius()


func _apply_radius() -> void:
	if _collision_shape == null:
		return
	var circle := _collision_shape.shape as CircleShape2D
	if circle == null:
		return
	circle.radius = radius
