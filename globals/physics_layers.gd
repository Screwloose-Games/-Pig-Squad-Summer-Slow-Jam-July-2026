class_name PhysicsLayers
extends RefCounted

## Physics layer numbers, mirroring [layer_names] in project.godot.
## These are layer *numbers* (1-based, as taken by set_collision_layer_value and
## set_collision_mask_value), not bitmask values.
##
## Rule of thumb for this project: static bodies (world, gladiator) keep an empty
## collision_mask and never scan. Only the junk scans, so junk alone decides what it
## touches. See JunkObstacle for why that matters.

const WORLD: int = 1
const JUNK: int = 2
const GLADIATOR: int = 3
