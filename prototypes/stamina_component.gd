class_name StaminaComponent
extends Node
## Tracks a unit's stamina and emits a signal on change. Attacks spend stamina; unlike
## health there is no regen and no death — an empty bar simply slows the unit's attacks.
## Items are the only way stamina comes back (see StaminaRestoreEffect).

signal stamina_changed(current_stamina: int, max_stamina: int)
## Stamina an item actually put back, which is not the item's amount when the clamp at max
## ate part of it. Fires whether or not the unit was exhausted at the time.
signal restored(amount: int)
## The bar just hit empty. Emitted on the crossing only — the exhausted *state* is polled
## every frame by BattleUnit._speed_scale(), and a per-frame poll is no use to a listener
## that needs to react once.
signal depleted
## The bar has something in it again after being empty. The other half of the pair above.
signal recovered

var max_stamina: int = 100
var current_stamina: int = 100:
	set(value):
		current_stamina = clampi(value, 0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)

## Last observed has_stamina(), so _emit_crossing can tell a real crossing from a change
## that left the unit on the same side of empty.
var _had_stamina: bool = true


func initialize(new_max_stamina: int) -> void:
	max_stamina = new_max_stamina
	# Seeded to where the unit is about to land, so a fresh unit never announces a crossing
	# it did not make.
	_had_stamina = new_max_stamina > 0
	current_stamina = new_max_stamina


func consume(amount: int) -> void:
	current_stamina -= amount
	_emit_crossing()


func restore(amount: int) -> void:
	# The clamp lives in the setter, so what the potion was worth is only knowable by
	# reading the value back. See HealthComponent.heal, which does the same.
	var before := current_stamina
	current_stamina += amount
	var gained := current_stamina - before
	if gained > 0:
		restored.emit(gained)
	# After the restore, not inside the setter: the drink is what caused the recovery, so
	# it has to be the thing that reads first.
	_emit_crossing()


func has_stamina() -> bool:
	return current_stamina > 0


## Reports a move across empty, and only a move — called by the two mutators rather than by
## the setter so the cause (the beat that spent it, the item that refilled it) reads first.
func _emit_crossing() -> void:
	var has := has_stamina()
	if has == _had_stamina:
		return
	_had_stamina = has
	if has:
		recovered.emit()
	else:
		depleted.emit()
