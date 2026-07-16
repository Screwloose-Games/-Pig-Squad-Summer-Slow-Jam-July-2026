class_name JunkItem
extends RigidBody2D

## A single piece of junk. Heavy and hard to shove when resting in the pile;
## light and easy to lift while carried by the mouse (see DragController).

# Mass difference so carried object can hardly move uncarried object
@export var heavy_mass: float = 4.0
@export var carried_mass: float = 0.4

# Gravity difference so carried object can be lifted easily, others behave normally
@export var heavy_gravity_scale: float = 1.0
@export var carried_gravity_scale: float = 0.15

var is_carried: bool = false


func _ready() -> void:
	add_to_group("junk")
	_apply_heavy()
	rotation = randf_range(-PI, PI)


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
