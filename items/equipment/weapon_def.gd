class_name WeaponDef
extends EquipmentDef

## A piece the unit attacks with. While equipped its damage replaces UnitStats.damage,
## and every landed strike costs 1 durability.

@export var damage: int = 8
