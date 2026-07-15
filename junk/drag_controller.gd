extends Node2D

## Handles mouse dragging of junk.
##
## Kept separate from JunkItem for the following reasons:
## 1. Resolves multi-object clicks (currently an edge case but also future proof if we add z-indexing)
## 2. Drag state handling: there can only be 1 dragged object at a time
## 3. Better to do input handling once in one place versus potentially multiplied over many junk objects
##
## The carried junk is driven toward the cursor by a spring force that is clamped to max_force.
## The clamp is key: just enough force to nudge junk but not enough to lift it.

## Pull strength toward the cursor (per pixel of offset).
@export var stiffness: float = 120.0
## Velocity damping to prevent overshoot/wobble (unless we want this?).
@export var damping: float = 12.0
## Hard cap on drag force. Tune so a carried piece shoves loose junk but cannot lift junk if buried.
@export var max_force: float = 6000.0

var _dragged: JunkItem = null


# Use _input (not _unhandled_input) so the click is seen before the viewport's
# physics object picking or any Control can consume it.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_pick()
		else:
			_release()


func _physics_process(_delta: float) -> void:
	if _dragged == null:
		return
	if not is_instance_valid(_dragged):
		_dragged = null
		return
	var target := get_global_mouse_position()
	var force := (target - _dragged.global_position) * stiffness - _dragged.linear_velocity * damping
	force = force.limit_length(max_force)
	_dragged.apply_central_force(force)


func _try_pick() -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_bodies = true
	var hits := space.intersect_point(params, 32)

	# Among the pieces under the cursor, grab the one drawn on top (latest sibling).
	var best: JunkItem = null
	var best_order := -1
	for hit in hits:
		var collider = hit.collider
		if collider is JunkItem and collider.get_index() > best_order:
			best_order = collider.get_index()
			best = collider

	if best != null:
		_dragged = best
		_dragged.set_carried(true)


func _release() -> void:
	if _dragged != null:
		_dragged.set_carried(false)
		_dragged = null
