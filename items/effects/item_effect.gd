class_name ItemEffect
extends Resource

## What using an item on a unit does, authored as a sub-resource on an ItemDef.
##
## One subclass per effect (HealEffect, StaminaRestoreEffect, ...), the extension point
## ItemDef's doc promised: defs stay closed to modification while effects stay open to
## extension, and no `match type:` switch ever has to learn about a new item.


## Override in a subclass. The base does nothing but complain, so a def wired to a bare
## ItemEffect is loud in the log instead of silently inert.
func apply(_unit: BattleUnit) -> void:
	push_warning("ItemEffect.apply() not overridden; item effect does nothing.")
