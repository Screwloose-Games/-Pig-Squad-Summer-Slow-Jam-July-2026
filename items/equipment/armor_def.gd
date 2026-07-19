class_name ArmorDef
extends EquipmentDef

## A piece that soaks hits. The armor values of every equipped armor piece sum into a
## flat reduction of incoming damage (clamped at 0), and each hit costs one randomly
## chosen equipped armor piece 1 durability.

@export var armor: int = 3
