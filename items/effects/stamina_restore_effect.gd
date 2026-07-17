class_name StaminaRestoreEffect
extends ItemEffect

## Restores stamina. The potion item's effect.

@export var amount: int = 25


func apply(unit: BattleUnit) -> void:
	unit.stamina_component.restore(amount)
