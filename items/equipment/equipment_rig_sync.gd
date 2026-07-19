extends Node

## Mirrors an EquipmentComponent's slots onto the GladiatorBones rig's *_equipped
## toggles. Mounted beside the component under a BattleUnit whose %Sprite is the rig.
##
## A separate node so EquipmentComponent never learns rig property names: a unit with
## equipment but a different (or no) rig simply skips visuals. New gear art is one
## more entry here plus a prop on the rig — no code elsewhere changes.

const SLOT_PROPERTIES := {
	EquipmentDef.Slot.RIGHT_HAND: &"sword_equipped",
	EquipmentDef.Slot.HEAD: &"helmet_equipped",
}

var _equipment: EquipmentComponent
var _rig: Node2D


func _ready() -> void:
	var unit := get_parent() as BattleUnit
	if unit == null:
		return
	if not unit.is_node_ready():
		# unit.sprite is @onready; the parent readies after its children.
		await unit.ready
	_rig = unit.sprite
	_equipment = unit.equipment
	if _equipment == null or _rig == null:
		return
	_equipment.changed.connect(_on_changed)
	for slot in SLOT_PROPERTIES:
		_on_changed(slot)


func _on_changed(slot: EquipmentDef.Slot) -> void:
	if SLOT_PROPERTIES.has(slot):
		_rig.set(SLOT_PROPERTIES[slot], _equipment.has_slot(slot))
