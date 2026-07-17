class_name PhysicsLayers
extends RefCounted

## Physics layer numbers, mirroring [layer_names] in project.godot.
## These are layer *numbers* (1-based, as taken by set_collision_layer_value and
## set_collision_mask_value), not bitmask values.
##
## Rule of thumb for this project: static bodies (world, gladiator) keep an empty
## collision_mask and never scan. Only items scan, so items alone decide what they
## touch. See ItemObstacle for why that matters.

const WORLD: int = 1
const ITEM: int = 2
const GLADIATOR: int = 3
## Items parked in a hotbar slot. Nothing scans this layer except the DragController's
## pick query, so a slotted item is grabbable but invisible to the pile's physics.
const SLOTTED_ITEM: int = 4
