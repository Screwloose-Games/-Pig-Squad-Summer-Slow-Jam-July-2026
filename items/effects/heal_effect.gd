class_name HealEffect
extends ItemEffect

## Restores health. The meat item's effect.

@export var amount: int = 25


func apply(unit: BattleUnit) -> void:
	unit.health_component.heal(amount)
