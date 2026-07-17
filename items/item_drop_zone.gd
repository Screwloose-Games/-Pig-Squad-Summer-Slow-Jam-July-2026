class_name ItemDropZone
extends Area2D

## Drop this under a BattleUnit to make it a valid target for released items — the same
## mounting pattern as ItemObstacle: the host needs no script and knows nothing about items.
##
## Sits on the gladiator layer with an empty mask, per the project rule that only items
## scan. Nothing physically collides with an Area2D; the only thing that ever finds this
## zone is the DragController's areas-only release query, which is also why sharing the
## gladiator layer with ItemObstacle is safe — that query skips bodies entirely.


## The unit an item dropped here should affect.
func get_unit() -> BattleUnit:
	return get_parent() as BattleUnit


## Hover feedback while a usable item is dragged over this zone: outlines the host
## unit so releasing obviously means something. Toggled by the DragController.
func set_highlighted(on: bool) -> void:
	var unit := get_unit()
	if unit != null:
		unit.set_outline(on)
