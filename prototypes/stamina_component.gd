class_name StaminaComponent
extends Node
## Tracks a unit's stamina and emits a signal on change. Attacks spend stamina; unlike
## health there is no regen and no death — an empty bar simply slows the unit's attacks.
## Items are the only way stamina comes back (see StaminaRestoreEffect).

signal stamina_changed(current_stamina: int, max_stamina: int)

var max_stamina: int = 100
var current_stamina: int = 100:
	set(value):
		current_stamina = clampi(value, 0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)


func initialize(new_max_stamina: int) -> void:
	max_stamina = new_max_stamina
	current_stamina = new_max_stamina


func consume(amount: int) -> void:
	current_stamina -= amount


func restore(amount: int) -> void:
	current_stamina += amount


func has_stamina() -> bool:
	return current_stamina > 0
