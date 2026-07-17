extends Node2D

## Handles mouse dragging of items.
##
## Kept separate from Item for the following reasons:
## 1. Resolves multi-object clicks (currently an edge case but also future proof if we add z-indexing)
## 2. Drag state handling: there can only be 1 dragged object at a time
## 3. Better to do input handling once in one place versus potentially multiplied over many item objects
##
## The carried item is driven toward the cursor by a spring force that is clamped to max_force.
## The clamp is key: just enough force to nudge an item but not enough to lift it.

## Pull strength toward the cursor (per pixel of offset).
@export var stiffness: float = 120.0
## Velocity damping to prevent overshoot/wobble (unless we want this?).
@export var damping: float = 12.0
## Hard cap on drag force. Tune so a carried piece shoves loose items but cannot lift one if buried.
@export var max_force: float = 6000.0

var _dragged: Item = null

## Drop zone the current drag is hovering, kept so its highlight can be switched
## off the moment the drag leaves it, ends, or the item despawns mid-drag.
var _hover_zone: ItemDropZone = null


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
		_set_hover_zone(null)
		return
	var target := get_global_mouse_position()
	var force := (target - _dragged.global_position) * stiffness - _dragged.linear_velocity * damping
	force = force.limit_length(max_force)
	_dragged.apply_central_force(force)
	_update_hover()


## Highlights the unit the drag is currently over, but only when releasing would
## actually do something: the item must have an effect and the unit must be alive.
func _update_hover() -> void:
	var zone: ItemDropZone = null
	if _dragged.has_effect():
		zone = _drop_zone_at(get_global_mouse_position())
		if zone == null:
			zone = _drop_zone_at(_dragged.global_position)
		if zone != null:
			var unit := zone.get_unit()
			if unit == null or not unit.is_alive():
				zone = null
	_set_hover_zone(zone)


func _set_hover_zone(zone: ItemDropZone) -> void:
	if zone == _hover_zone:
		return
	if _hover_zone != null and is_instance_valid(_hover_zone):
		_hover_zone.set_highlighted(false)
	_hover_zone = zone
	if _hover_zone != null:
		_hover_zone.set_highlighted(true)


func _try_pick() -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_bodies = true
	# Only items are pickable: without this the query also returns the arena and the
	# gladiators, and a click on either would waste the 32-hit budget. Slotted items are
	# frozen (static) but intersect_point still reports them, so they lift straight out.
	params.collision_mask = (
		1 << (PhysicsLayers.ITEM - 1)
		| 1 << (PhysicsLayers.SLOTTED_ITEM - 1)
	)
	var hits := space.intersect_point(params, 32)

	# Among the pieces under the cursor, grab the one drawn on top (latest sibling).
	var best: Item = null
	var best_order := -1
	for hit in hits:
		var collider = hit.collider
		if collider is Item and collider.get_index() > best_order:
			best_order = collider.get_index()
			best = collider

	if best != null:
		_dragged = best
		_dragged.set_carried(true)


func _release() -> void:
	# Items despawn on their own timer, so the carried one can be freed out from under us
	# mid-drag. is_instance_valid is the dependable test for that, and _dragged is cleared
	# either way so a dangling reference is never left behind.
	if not is_instance_valid(_dragged):
		_dragged = null
		_set_hover_zone(null)
		return
	var item := _dragged
	_dragged = null
	_set_hover_zone(null)
	item.set_carried(false)
	# UI wins over world: a hotbar slot under the cursor claims the item before any
	# gladiator does. Scenes without a hotbar (level_01) skip straight past this.
	var hotbar := get_tree().get_first_node_in_group("hotbar") as Hotbar
	if hotbar != null and hotbar.try_place(item, get_viewport().get_mouse_position()):
		return
	_try_drop_on_unit(item)


## Uses the released item on whichever unit's drop zone sits under the cursor — or under
## the item itself, which lags the cursor on its spring and is what the player is watching.
func _try_drop_on_unit(item: Item) -> void:
	if not item.has_effect():
		return
	for point in [get_global_mouse_position(), item.global_position]:
		var zone := _drop_zone_at(point)
		if zone != null:
			var unit := zone.get_unit()
			if unit != null and unit.is_alive():
				item.use_on(unit)
				return


## Areas-only, so the ItemObstacle body sharing the gladiator layer stays invisible here.
func _drop_zone_at(point: Vector2) -> ItemDropZone:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1 << (PhysicsLayers.GLADIATOR - 1)
	for hit in space.intersect_point(params, 4):
		var zone := hit.collider as ItemDropZone
		if zone != null:
			return zone
	return null
