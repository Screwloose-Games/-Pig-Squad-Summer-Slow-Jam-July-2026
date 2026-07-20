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

## The wearer, kept so the bus relays can name whose gear this is. Null in a scene where
## this component was mounted under something that is not a BattleUnit.
var _unit: BattleUnit


func _ready() -> void:
	_unit = get_parent() as BattleUnit
	if _unit != null:
		_unit.equipment = self


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
	# `changed` carries only the slot, which cannot tell a sword from a helmet or a fresh
	# equip from a swap. This one says what went on and whether it displaced anything.
	GlobalSignalBus.unit_equipped.emit(_unit, eq.slot, item_def, previous != null)
	return previous


func has_slot(slot: EquipmentDef.Slot) -> bool:
	return _pieces.has(slot)


## Whether a swing from this unit lands as a weapon hit — the same test roll_attack_damage
## makes before it reads a damage value.
func has_weapon() -> bool:
	var piece: EquippedPiece = _pieces.get(EquipmentDef.Slot.RIGHT_HAND)
	return piece != null and piece.item_def.equipment is WeaponDef


## Whether anything is worn that would soak an incoming hit.
func has_armor() -> bool:
	for slot in _pieces:
		if (_pieces[slot] as EquippedPiece).item_def.equipment is ArmorDef:
			return true
	return false


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
	if piece.durability == 1:
		# One hit left. The durability pie is hidden unless the piece is hovered or dragged
		# (see Item.set_durability_shown), so this is the only warning the player can get.
		GlobalSignalBus.unit_equipment_nearly_broken.emit(_unit, slot, piece.item_def)
	if piece.durability <= 0:
		# Broken gear vanishes — no world drop. `changed` alone drives visual sync.
		_pieces.erase(slot)
		broken.emit(slot, piece.item_def)
		GlobalSignalBus.unit_equipment_broke.emit(_unit, slot, piece.item_def)
		changed.emit(slot)
