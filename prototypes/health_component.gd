class_name HealthComponent
extends Node
## Tracks a unit's health and emits signals on change and death.

signal health_changed(current_health: int, max_health: int)
signal died
## Healing that actually landed, and the amount it landed for — which is not the item's
## amount when the clamp at max ate part of it.
signal healed(amount: int)
## Healing spent on a unit already at full health. The item is gone and nothing changed.
signal heal_wasted

var max_health: int = 100
var current_health: int = 100:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health, max_health)


func initialize(new_max_health: int) -> void:
	max_health = new_max_health
	current_health = new_max_health


func take_damage(amount: int) -> void:
	if not is_alive():
		return
	current_health -= amount
	if current_health == 0:
		died.emit()


func heal(amount: int) -> void:
	if not is_alive():
		return
	# The clamp lives in the setter, so the only way to know what the heal was worth is to
	# read the value back afterwards. A gain of 0 means the bar was already full.
	var before := current_health
	current_health += amount
	var gained := current_health - before
	if gained > 0:
		healed.emit(gained)
	else:
		heal_wasted.emit()


func is_alive() -> bool:
	return current_health > 0
