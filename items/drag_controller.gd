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

## Item currently showing its durability pie: the dragged item while a drag is live,
## else whatever equipment sits under the idle cursor.
var _hovered: Item = null


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
		_set_hovered_item(_item_at_point(get_global_mouse_position()))
		return
	if not is_instance_valid(_dragged):
		# Despawned out from under the cursor. The drag is over even though the player
		# never let go, so anything running for its duration has to be told.
		_end_drag()
		_set_hovered_item(null)
		return
	_set_hovered_item(_dragged)
	var target := get_global_mouse_position()
	var force := (target - _dragged.global_position) * stiffness - _dragged.linear_velocity * damping
	force = force.limit_length(max_force)
	_dragged.apply_central_force(force)
	_update_hover()


## Highlights the unit the drag is currently over, but only when releasing would
## actually do something: the unit must be alive and able to receive this item
## (an effect for anyone, equipment only for a unit that can wear it).
func _update_hover() -> void:
	var zone := _drop_zone_at(get_global_mouse_position())
	if zone == null:
		zone = _drop_zone_at(_dragged.global_position)
	if zone != null:
		var unit := zone.get_unit()
		if unit == null or not unit.is_alive() or not _dragged.can_use_on(unit):
			zone = null
	_set_hover_zone(zone)


func _set_hovered_item(item: Item) -> void:
	if item == _hovered:
		return
	if is_instance_valid(_hovered):
		_hovered.set_durability_shown(false)
	_hovered = item
	if _hovered != null:
		_hovered.set_durability_shown(true)


func _set_hover_zone(zone: ItemDropZone) -> void:
	if zone == _hover_zone:
		return
	var had_zone: bool = _hover_zone != null
	if had_zone and is_instance_valid(_hover_zone):
		_hover_zone.set_highlighted(false)
	_hover_zone = zone
	# This early-returns on an unchanged zone, so these fire once per hover rather than
	# once per physics frame.
	if had_zone:
		# The carried item can already be freed here — a drag ended by a despawn clears the
		# zone on its way out — so the cue reports the loss without naming a dead node.
		GlobalSignalBus.item_hover_target_lost.emit(
			_dragged if is_instance_valid(_dragged) else null
		)
	if _hover_zone != null:
		_hover_zone.set_highlighted(true)
		GlobalSignalBus.item_hover_target_entered.emit(_dragged, _hover_zone.get_unit())


func _try_pick() -> void:
	var best := _item_at_point(get_global_mouse_position())
	if best != null:
		_dragged = best
		_dragged.set_carried(true)
		GlobalSignalBus.item_drag_started.emit(_dragged)


## Topmost item under a world point, or null. Serves both pickup and idle hover.
func _item_at_point(point: Vector2) -> Item:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_bodies = true
	# Only items are pickable: without this the query also returns the arena and the
	# gladiators, and a click on either would waste the 32-hit budget. Slotted items are
	# frozen (static) but intersect_point still reports them, so they lift straight out.
	params.collision_mask = (
		1 << (PhysicsLayers.ITEM - 1)
		| 1 << (PhysicsLayers.SLOTTED_ITEM - 1)
	)
	var hits := space.intersect_point(params, 32)

	# Among the pieces under the cursor, prefer the one drawn on top (latest sibling).
	var best: Item = null
	var best_order := -1
	for hit in hits:
		var collider = hit.collider
		if collider is Item and collider.get_index() > best_order:
			best_order = collider.get_index()
			best = collider
	return best


func _release() -> void:
	# Items despawn on their own timer, so the carried one can be freed out from under us
	# mid-drag. is_instance_valid is the dependable test for that, and _dragged is cleared
	# either way so a dangling reference is never left behind.
	var item := _end_drag()
	if item == null:
		return
	item.set_carried(false)
	# UI wins over world: a hotbar slot under the cursor claims the item before any
	# gladiator does. Scenes without a hotbar (level_01) skip straight past this.
	var hotbar := get_tree().get_first_node_in_group("hotbar") as Hotbar
	if hotbar != null and hotbar.try_place(item, get_viewport().get_mouse_position()):
		return
	_try_drop_on_unit(item)


## Clears the drag state and reports that the drag is over, whichever way it ended — the
## player letting go, or the item being freed mid-carry. Returns the item, or null if it
## did not survive. The one place a drag ends, so nothing running for the drag's duration
## can be left hanging.
func _end_drag() -> Item:
	var item := _dragged
	# Before clearing _dragged: the hover-lost cue names the item that was being carried.
	_set_hover_zone(null)
	_dragged = null
	if not is_instance_valid(item):
		GlobalSignalBus.item_drag_ended.emit(null)
		return null
	GlobalSignalBus.item_drag_ended.emit(item)
	return item


## Uses the released item on whichever unit's drop zone sits under the cursor — or under
## the item itself, which lags the cursor on its spring and is what the player is watching.
## Re-queries rather than reusing _hover_zone, which _update_hover already nulled for a
## target that cannot take this item — the refusal is exactly what has to be reported here.
func _try_drop_on_unit(item: Item) -> void:
	var refused_by: BattleUnit = null
	for point in [get_global_mouse_position(), item.global_position]:
		var zone := _drop_zone_at(point)
		if zone == null:
			continue
		var unit := zone.get_unit()
		if unit == null or not unit.is_alive():
			continue
		if item.can_use_on(unit):
			item.use_on(unit)
			return
		refused_by = unit
	if refused_by != null:
		# The player aimed at a gladiator and was turned down — junk, or equipment on a
		# fighter that cannot wear it. Distinct from dropping on empty sand.
		GlobalSignalBus.item_drop_rejected.emit(item, refused_by)
	else:
		GlobalSignalBus.item_drop_ignored.emit(item)


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
