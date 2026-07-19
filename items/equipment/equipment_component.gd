class_name EquipmentComponent
extends Node

## What a unit is wearing, one piece per EquipmentDef.Slot.
##
## Mounted as a host-scene child of a BattleUnit, the way ItemDropZone and ItemObstacle
## are: the unit scenes stay equipment-ignorant, and a unit without this component
## (every enemy) fights exactly as before. The component registers itself on the parent
## in _ready(), which runs before the parent's — BattleUnit never looks children up.
##
## Durability travels as a plain value because ItemDef is a shared resource: the same
## .tres backs every sword in the pile, so per-piece wear can never live on it.

signal changed(slot: EquipmentDef.Slot)
signal broken(slot: EquipmentDef.Slot, item_def: ItemDef)


class EquippedPiece:
	var item_def: ItemDef
	var durability: int


var _pieces: Dictionary = {}


func _ready() -> void:
	var unit := get_parent() as BattleUnit
	if unit != null:
		unit.equipment = self


## Installs a piece and returns whatever it displaced from the same slot (or null),
## so the caller can put the old piece back into the world.
func equip(item_def: ItemDef, durability: int) -> EquippedPiece:
	var eq: EquipmentDef = item_def.equipment
	var previous: EquippedPiece = _pieces.get(eq.slot)
	var piece := EquippedPiece.new()
	piece.item_def = item_def
	piece.durability = clampi(durability, 1, eq.max_durability)
	_pieces[eq.slot] = piece
	changed.emit(eq.slot)
	return previous


func has_slot(slot: EquipmentDef.Slot) -> bool:
	return _pieces.has(slot)


## Damage for one landed swing. The value is read before the wear is charged, so the
## strike that empties the weapon still lands at full weapon damage — it did connect.
func roll_attack_damage(fallback: int) -> int:
	var piece: EquippedPiece = _pieces.get(EquipmentDef.Slot.RIGHT_HAND)
	if piece == null or not piece.item_def.equipment is WeaponDef:
		return fallback
	var damage: int = (piece.item_def.equipment as WeaponDef).damage
	_wear(EquipmentDef.Slot.RIGHT_HAND, piece)
	return damage


## Mitigates one incoming hit. Every equipped armor piece contributes its full value —
## including one about to break on this very hit — and exactly one random piece takes
## the 1 point of wear.
func absorb_hit(amount: int) -> int:
	var armor_slots: Array = []
	var total_armor := 0
	for slot in _pieces:
		var armor_def := (_pieces[slot] as EquippedPiece).item_def.equipment as ArmorDef
		if armor_def != null:
			total_armor += armor_def.armor
			armor_slots.append(slot)
	if armor_slots.is_empty():
		return amount
	var worn_slot: EquipmentDef.Slot = armor_slots.pick_random()
	_wear(worn_slot, _pieces[worn_slot])
	return maxi(0, amount - total_armor)


func _wear(slot: EquipmentDef.Slot, piece: EquippedPiece) -> void:
	piece.durability -= 1
	if piece.durability <= 0:
		# Broken gear vanishes — no world drop. `changed` alone drives visual sync.
		_pieces.erase(slot)
		broken.emit(slot, piece.item_def)
		changed.emit(slot)
