class_name HotbarSlot
extends PanelContainer

## One numbered square of the hotbar. Holds at most one Item.
##
## The slot never owns the item's node: the item stays a live RigidBody2D in the world,
## frozen at this slot's world-space centre (see Item.enter_slot). That keeps the despawn
## timer and blink warning running unchanged, and lets the DragController lift it back out
## with the same physics query it uses on the pile. The panel is drawn mostly transparent
## because the item renders on the world canvas *behind* this UI layer.

## The green quickslot square. It backs the item in the *world*, not on this UI layer: the
## item parked here is a live world body (see enter_slot), and a backing drawn on the UI
## CanvasLayer above it would hide it. So the art lives behind the item, at world z_index 0.
const BACKING_TEXTURE: Texture2D = preload("res://assets/art/ui/inv_slot.png")

## Scale from the 126px art down to roughly this slot's footprint.
const BACKING_SCALE: Vector2 = Vector2(0.7, 0.7)

## Which number key uses this slot; also the label in the corner.
@export var slot_number: int = 1

var item: Item = null

# The world-space green square that frames whatever item sits in this slot.
var _backing: Sprite2D = null

# A direct child, not a %unique name: four slots live in one scene, and unique names
# are registered per-owner, so four %NumberLabel registrations would collide.
@onready var _number_label: Label = $NumberLabel


func _ready() -> void:
	_number_label.text = str(slot_number)
	_spawn_backing()


# The slot's screen rect is only laid out after entering the tree, and the backing tracks it
# in world space; four sprites a frame is cheap and keeps it correct across resizes.
func _process(_delta: float) -> void:
	if is_instance_valid(_backing):
		_backing.global_position = _world_center()


# The backing is parented into the world, not under this UI node, so it does not die with the
# slot automatically — free it explicitly.
func _exit_tree() -> void:
	if is_instance_valid(_backing):
		_backing.queue_free()


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


## Drops the green backing square into the world behind the item plane. Skipped when the slot
## has no world to live in (e.g. the hotbar scene opened on its own).
func _spawn_backing() -> void:
	var world: Node = get_tree().current_scene
	if world == null:
		return
	_backing = Sprite2D.new()
	_backing.texture = BACKING_TEXTURE
	_backing.scale = BACKING_SCALE
	_backing.z_index = 0
	# Deferred: this runs from the slot's _ready() while the scene root is still setting up its
	# own children, when a direct add_child() is refused. _process places it once it is in-tree.
	world.add_child.call_deferred(_backing)
