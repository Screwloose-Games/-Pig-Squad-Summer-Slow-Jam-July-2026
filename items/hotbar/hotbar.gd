class_name Hotbar
extends HBoxContainer

## The four-slot item bar at the bottom of the screen. Items are stored by dropping them
## onto a slot and spent on the hero with the number keys (see HotbarSlot for how a
## slotted item keeps living in the world).
##
## The DragController finds this node through the "hotbar" group, so scenes without a
## hotbar (or without a hero) need no special casing anywhere.

const SLOT_COUNT: int = 4

## Who the number keys spend items on. Assigned in the host scene.
@export var hero: BattleUnit


func _ready() -> void:
	add_to_group("hotbar")


## Offers a released item to whichever slot the cursor or the item itself sits over.
## The item's own position counts because the player watches the item, not the cursor:
## the drag spring leaves the body lagging the mouse, and the arena floor can hold it
## short of a slot its art already visually covers.
func try_place(item: Item, screen_pos: Vector2) -> bool:
	var item_screen: Vector2 = item.get_viewport().get_canvas_transform() * item.global_position
	for slot in _slots():
		var rect := slot.get_global_rect()
		if rect.has_point(screen_pos) or rect.has_point(item_screen):
			slot.place(item)
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	for i in SLOT_COUNT:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			_use_slot(i)
			get_viewport().set_input_as_handled()
			return


func _use_slot(index: int) -> void:
	if hero == null or not hero.is_alive():
		return
	var slots := _slots()
	if index < slots.size():
		slots[index].use_on(hero)


func _slots() -> Array[HotbarSlot]:
	var slots: Array[HotbarSlot] = []
	for child in get_children():
		if child is HotbarSlot:
			slots.append(child)
	return slots
