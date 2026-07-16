class_name ItemDef
extends Resource

## One kind of item, authored as data (.tres per type), the way UnitStats does for units.
##
## The Item scene is a single generic body; everything that makes a sword a sword and not
## a potion lives here. A fifth item is a new .tres and a spawner entry — no new scene and
## no new script.
##
## When per-type effects arrive they belong here too, as an `effect: ItemEffect` sub-resource
## with one subclass per effect. That keeps this def closed to modification while effects stay
## open to extension, and avoids a `match type:` switch that every new item would have to edit.
## The enum below is for identification and UI, deliberately not for dispatch.

enum Type { JUNK, HELMET, MEAT, POTION, SWORD }

@export var display_name: String = "Item"
@export var type: Type = Type.JUNK

## Art for this type. Left null by JUNK, which is drawn as the plain grey square the pile
## used before there was any art — so the defaults below already describe a piece of junk.
@export var texture: Texture2D

## World-space footprint, driving both the sprite scale and the collision box so the art and
## the physics cannot drift apart. Authored at the source art's aspect ratio: the sprite is
## stretched to fit this exactly, so a mismatched aspect visibly squashes the art.
## Kept near the 48px the arena and the drag forces were tuned around.
@export var size: Vector2 = Vector2(48, 48)

## Share of a spawner's mix, relative to the other defs on that spawner. 0 disables this type
## there. Relative rather than absolute so rarity is tuned by editing defs, never code.
@export var spawn_weight: float = 1.0
