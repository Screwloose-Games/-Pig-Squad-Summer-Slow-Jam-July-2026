class_name EquipmentDef
extends Resource

## Wearable identity of an item, authored as a sub-resource on an ItemDef the same way
## ItemEffect is: the def stays closed to modification while equipment kinds stay open
## to extension. Subclasses (WeaponDef, ArmorDef) carry the per-kind stats; nothing
## dispatches on ItemDef.Type.

## Where a piece sits on a unit. One piece per slot; equipping into an occupied slot
## displaces the old piece. CHEST and LEFT_HAND await the breastplate and shield.
enum Slot { HEAD, CHEST, RIGHT_HAND, LEFT_HAND }

@export var slot: Slot = Slot.HEAD

## Wear points when brand new. Randomly spawned equipment rolls its starting
## durability in [1, max_durability]; see Item._ready().
@export var max_durability: int = 3
