class_name JunkItem
extends RigidBody2D

## A single piece of junk. Heavy and hard to shove when resting in the pile;
## light and easy to lift while carried by the mouse (see DragController).
##
## Every piece despawns on its own timer, which is what keeps the pile from growing
## without bound. It blinks out the tail of that timer first so a piece never simply
## vanishes: the player gets told before the junk they were reaching for is gone.

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

var is_carried: bool = false

@onready var _despawn_timer: Timer = %DespawnTimer


func _ready() -> void:
	add_to_group("junk")
	_apply_heavy()
	rotation = randf_range(-PI, PI)
	_despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	_start_despawn_countdown()


## Called by the DragController on pickup/release to swap between the
## light (carried) and heavy (resting) physics profiles.
func set_carried(carried: bool) -> void:
	is_carried = carried
	if carried:
		mass = carried_mass
		gravity_scale = carried_gravity_scale
	else:
		_apply_heavy()
	# Carried junk passes straight through gladiators, so a piece can be pulled clear
	# of the pile without shoving them around. Junk still scans world and junk while
	# carried: it must not sink through the floor, and it should still nudge the pile.
	# This one line is the whole opt-out only because gladiators never scan junk back —
	# see JunkObstacle.
	set_collision_mask_value(PhysicsLayers.GLADIATOR, not carried)


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
