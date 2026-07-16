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
## Battle presentation (nameplates, damage numbers, the end overlay) is deliberately
## left out — auto-battle-prototype.tscn already covers that. This one is about junk.

@onready var hero: BattleUnit = %HeroGladiator
@onready var enemy: BattleUnit = %EnemyGladiator


func _ready() -> void:
	hero.setup(enemy)
	enemy.setup(hero)
	hero.start_fighting()
	enemy.start_fighting()
