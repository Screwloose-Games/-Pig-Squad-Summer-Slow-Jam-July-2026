class_name HealthComponent
extends Node
## Tracks a unit's health and emits signals on change and death.

signal health_changed(current_health: int, max_health: int)
signal died

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
	current_health += amount


func is_alive() -> bool:
	return current_health > 0
