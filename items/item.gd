class_name Item
extends RigidBody2D

## A single item. Heavy and hard to shove when resting in the pile;
## light and easy to lift while carried by the mouse (see DragController).
##
## Deliberately generic: this body knows nothing about swords or potions. Its identity —
## art, footprint, and later its effect — arrives as an ItemDef, so every type shares
## one scene and one script.
##
## Every item despawns on its own timer, which is what keeps the pile from growing
## without bound. It blinks out the tail of that timer first so an item never simply
## vanishes: the player gets told before the item they were reaching for is gone.

## Authored size of the placeholder square, which the JUNK def is drawn with. Scaling the
## placeholder against this is what lets junk honour ItemDef.size like every other type.
const PLACEHOLDER_SIZE: Vector2 = Vector2(48, 48)

## What kind of item this is. Assigned by the spawner *before* the node enters the tree,
## because _ready() is what stamps it onto the body.
@export var definition: ItemDef

# Mass difference so carried object can hardly move uncarried object
@export var heavy_mass: float = 4.0
@export var carried_mass: float = 0.4

# Gravity difference so carried object can be lifted easily, others behave normally
@export var heavy_gravity_scale: float = 1.0
@export var carried_gravity_scale: float = 0.15

@export_group("Despawn")
## Seconds this piece survives after spawning, blink included. 0 or less keeps it
## around forever, which is the old unbounded-pile behaviour.
@export var lifetime: float = 12.0
## Trailing slice of lifetime spent blinking as a warning, not added on top of it.
@export var blink_duration: float = 3.0
## Blinks per second while warning.
@export var blink_rate: float = 5.0
## Alpha each blink dips to. Kept above 0 so a blinking piece is still grabbable.
@export var blink_min_alpha: float = 0.2

## Fired when the DragController picks this item up, including out of a hotbar slot —
## that is the moment a slot holding this item must consider it gone.
signal grabbed

var is_carried: bool = false
var is_slotted: bool = false

@onready var _sprite: Sprite2D = %Sprite
@onready var _placeholder: Node2D = %Placeholder
@onready var _collision_shape: CollisionShape2D = %CollisionShape2D
@onready var _despawn_timer: Timer = %DespawnTimer


func _ready() -> void:
	add_to_group("items")
	_apply_definition()
	_apply_heavy()
	rotation = randf_range(-PI, PI)
	_despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	_start_despawn_countdown()


## Stamps this generic body with the identity in `definition`: art, footprint, collision.
func _apply_definition() -> void:
	if definition == null:
		push_warning("Item spawned without a definition; falling back to a plain square.")
		return

	# A fresh shape per item, the way ItemArena builds its slabs. The shape authored in the
	# scene is one resource shared by every instance, so resizing that would resize all junk.
	var box := RectangleShape2D.new()
	box.size = definition.size
	_collision_shape.shape = box

	# Junk carries no art and stays the grey square the pile has always used; every other
	# type hides the square and shows its sprite instead.
	var has_texture: bool = definition.texture != null
	_sprite.visible = has_texture
	_placeholder.visible = not has_texture
	if has_texture:
		_sprite.texture = definition.texture
		_sprite.scale = definition.size / definition.texture.get_size()
	else:
		_placeholder.scale = definition.size / PLACEHOLDER_SIZE


## Called by the DragController on pickup/release to swap between the
## light (carried) and heavy (resting) physics profiles.
func set_carried(carried: bool) -> void:
	is_carried = carried
	if carried and is_slotted:
		_exit_slot()
	if carried:
		mass = carried_mass
		gravity_scale = carried_gravity_scale
	else:
		_apply_heavy()
	# A carried item passes straight through gladiators, so it can be pulled clear of the
	# pile without shoving them around. It still scans world and items while carried: it
	# must not sink through the floor, and it should still nudge the pile.
	# This one line is the whole opt-out only because gladiators never scan items back —
	# see ItemObstacle.
	set_collision_mask_value(PhysicsLayers.GLADIATOR, not carried)
	if carried:
		grabbed.emit()


func has_effect() -> bool:
	return definition != null and definition.effect != null


## The single consumption path: drop-on-gladiator and hotbar hotkeys both land here.
## Freeing the node takes the despawn timer and any blink tween with it.
func use_on(unit: BattleUnit) -> void:
	if not has_effect():
		return
	definition.effect.apply(unit)
	queue_free()


## Parks this item in a hotbar slot: frozen in place, upright, and moved to a layer
## nothing scans so the pile treats it as gone. The despawn countdown keeps running —
## a slot preserves the item, not its lifetime.
func enter_slot(at_global: Vector2) -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = at_global
	rotation = 0.0
	# The node-side writes above are not enough for a body that is mid-flight when it is
	# dropped: the physics server still owns a moving rigid body's state and delivers one
	# more sync after this call, snapping the item back to wherever it was released. Writing
	# the same state into the server directly is what makes the teleport stick.
	PhysicsServer2D.body_set_state(
		get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, at_global)
	)
	PhysicsServer2D.body_set_state(
		get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO
	)
	PhysicsServer2D.body_set_state(
		get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0
	)
	collision_layer = 0
	set_collision_layer_value(PhysicsLayers.SLOTTED_ITEM, true)
	collision_mask = 0
	is_slotted = true


## Undoes enter_slot when the item is grabbed back out. Runs before set_carried's
## gladiator opt-out so that line lands on the restored mask.
func _exit_slot() -> void:
	freeze = false
	collision_layer = 0
	set_collision_layer_value(PhysicsLayers.ITEM, true)
	set_collision_mask_value(PhysicsLayers.WORLD, true)
	set_collision_mask_value(PhysicsLayers.ITEM, true)
	set_collision_mask_value(PhysicsLayers.GLADIATOR, true)
	is_slotted = false


func _apply_heavy() -> void:
	mass = heavy_mass
	gravity_scale = heavy_gravity_scale


func _start_despawn_countdown() -> void:
	if lifetime <= 0.0:
		return
	# The timer only has to cover the quiet part; the blink tween runs out the rest, so
	# the two together add up to lifetime rather than overshooting it.
	_despawn_timer.start(maxf(0.05, lifetime - _warn_duration()))


func _on_despawn_timer_timeout() -> void:
	_blink_then_despawn()


func _blink_then_despawn() -> void:
	var warn: float = _warn_duration()
	if warn <= 0.0:
		queue_free()
		return
	var blinks: int = maxi(1, roundi(warn * blink_rate))
	var half_blink: float = warn / float(blinks) * 0.5
	var tween: Tween = create_tween()
	tween.set_loops(blinks)
	tween.tween_property(self, "modulate:a", blink_min_alpha, half_blink)
	tween.tween_property(self, "modulate:a", 1.0, half_blink)
	tween.finished.connect(queue_free)


## Blink can never outlast the piece it is warning about.
func _warn_duration() -> float:
	return minf(blink_duration, lifetime)
