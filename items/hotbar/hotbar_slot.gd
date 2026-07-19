class_name HotbarSlot
extends PanelContainer

## One numbered square of the hotbar. Holds at most one Item.
##
## The slot never owns the item's node: the item stays a live RigidBody2D in the world,
## frozen at this slot's world-space centre (see Item.enter_slot). That keeps the despawn
## timer and blink warning running unchanged, and lets the DragController lift it back out
## with the same physics query it uses on the pile. The panel is drawn mostly transparent
## because the item renders on the world canvas *behind* this UI layer.

## Which number key uses this slot; also the label in the corner.
@export var slot_number: int = 1

var item: Item = null

# A direct child, not a %unique name: four slots live in one scene, and unique names
# are registered per-owner, so four %NumberLabel registrations would collide.
@onready var _number_label: Label = $NumberLabel


func _ready() -> void:
	_number_label.text = str(slot_number)


func is_empty() -> bool:
	return not is_instance_valid(item)


## Takes ownership of a released item. A slot holds one item, so whatever was here
## before is despawned outright — replaced, not swapped.
func place(new_item: Item) -> void:
	var replaced := not is_empty()
	if replaced:
		_disconnect_item()
		item.queue_free()
	item = new_item
	item.enter_slot(_world_center())
	# Both exits from a slot funnel into _on_item_left: grabbed covers drag-out,
	# tree_exiting covers despawn-in-slot and consumption via use_on.
	item.grabbed.connect(_on_item_left)
	item.tree_exiting.connect(_on_item_left)
	# Overwriting is a real loss — the old item is gone for good, not returned to the pile.
	if replaced:
		GlobalSignalBus.hotbar_slot_replaced.emit(slot_number, item)
	else:
		GlobalSignalBus.hotbar_slot_filled.emit(slot_number, item)


## Spends the slotted item on `unit`. A junk-filled or empty slot is a quiet no-op — the
## Hotbar checks is_empty() first and reports the failure, so this stays a plain guard.
func use_on(unit: BattleUnit) -> void:
	if is_empty():
		return
	item.use_on(unit)


func _on_item_left() -> void:
	_disconnect_item()
	item = null
	# Neutral: dragged out, consumed and despawned in place all land here, and the grab and
	# consume cues carry the flavour for the first two.
	GlobalSignalBus.hotbar_item_removed.emit(slot_number)


func _disconnect_item() -> void:
	if item.grabbed.is_connected(_on_item_left):
		item.grabbed.disconnect(_on_item_left)
	if item.tree_exiting.is_connected(_on_item_left):
		item.tree_exiting.disconnect(_on_item_left)


## This panel lives on a CanvasLayer, so its rect is in screen space; the item it parks
## lives in the world. This is the inverse of the nameplate's world->screen conversion.
func _world_center() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_global_rect().get_center()
