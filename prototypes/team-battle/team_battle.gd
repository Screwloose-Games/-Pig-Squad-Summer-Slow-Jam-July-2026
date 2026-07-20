extends Node2D
## Prototype: one hero against a team of two, to exercise GladiatorMatch beyond 1-v-1.
##
## Everything the other combat prototypes do — go-signal, first blood, the result overlay —
## comes from the GladiatorMatch node, so the interesting part here is what it does that a
## 1-v-1 match cannot show: the match survives the first death, and the survivor on the
## losing side picks up a new target instead of standing idle. Only when *every* enemy is
## down does the hero win.
##
## The gladiators, damage numbers and end overlay are the same scenes the auto-battle
## prototype uses, unchanged. No nameplates: BattleNameplate tracks a *side* off the bus
## rather than a unit, so two enemy plates would both render whichever enemy last took a
## hit. Damage numbers and the death animations carry the read instead.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")

## Restarts the whole match. A raw keycode rather than an input action, matching the debug
## affordance in enemy-variants: project.godot defines only `pause`, and a prototype has no
## business editing shared project config.
const RESTART_KEY: Key = KEY_R

@onready var damage_numbers: Node2D = %DamageNumbers
@onready var gladiator_match: GladiatorMatch = %GladiatorMatch
@onready var end_overlay: BattleEndOverlay = %BattleEndOverlay


func _ready() -> void:
	GlobalSignalBus.unit_hurt.connect(_on_unit_hurt)
	_start_match()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if (event as InputEventKey).keycode == RESTART_KEY:
			_start_match()
			get_viewport().set_input_as_handled()


## Puts everyone back on their feet and runs a fresh match. Also the first-run path, so
## opening the scene and restarting go through the same code and cannot drift apart.
func _start_match() -> void:
	gladiator_match.stop()
	end_overlay.hide_result()
	for unit in gladiator_match.combatants():
		unit.reset_for_new_fight()
	gladiator_match.start()


func _on_unit_hurt(unit: Node2D, amount: int) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.setup(amount)
	# Position before adding: the number's _ready() reads its own position to seed the drift
	# animation, and _ready() fires the moment it enters the tree. The offset clears the top
	# of the art, which sits ~71px above the origin before the perspective scale.
	var spawn_at: Vector2 = unit.global_position + Vector2(-12.0, -90.0) * unit.scale
	number.position = damage_numbers.to_local(spawn_at)
	damage_numbers.add_child(number)
