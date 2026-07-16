extends Node2D
## Prototype: the auto-battler's gladiators standing in the junk field, so junk can be
## thrown in, pile up on the ground, and be rummaged through while they fight.
##
## Combines two prototypes without either learning about the other. The gladiators are
## the same battle_unit.tscn the auto-battle prototype uses and know nothing about
## junk — the hero only takes part because a JunkObstacle is mounted under him in this
## scene. Only the hero has one: junk lives in his ground plane, while the enemy sits
## up the perspective slope where junk never reaches.
##
## Nameplates and damage numbers are deliberately left out — auto-battle-prototype.tscn
## already covers those. This one is about junk. The end overlay earns its place because
## without it the fight has no visible ending: the loser just quietly stops.

var _battle_over: bool = false

@onready var hero: BattleUnit = %HeroGladiator
@onready var enemy: BattleUnit = %EnemyGladiator


func _ready() -> void:
	hero.setup(enemy)
	enemy.setup(hero)
	GlobalSignalBus.unit_died.connect(_on_unit_died)
	hero.start_fighting()
	enemy.start_fighting()


func _on_unit_died(unit: Node2D) -> void:
	if _battle_over:
		return
	_battle_over = true
	hero.stop_fighting()
	enemy.stop_fighting()
	# The overlay listens for this on the bus; it is not wired to this scene directly.
	GlobalSignalBus.battle_ended.emit(unit == enemy)
