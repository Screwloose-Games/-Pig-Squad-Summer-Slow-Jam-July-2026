extends Node2D
## Prototype: the auto-battler's gladiators standing in the item field, so items can be
## thrown in, pile up on the ground, and be rummaged through while they fight.
##
## Combines two prototypes without either learning about the other. The gladiators are
## the same battle_unit.tscn the auto-battle prototype uses and know nothing about
## items — the hero only takes part because an ItemObstacle is mounted under him in this
## scene. Only the hero has one: items live in his ground plane, while the enemy sits
## up the perspective slope where items never reach.
##
## Info nameplates are pinned to the top screen corners (hero left, enemy right) as the
## artist's stat blocks; floating damage numbers are reused from the auto-battle prototype.
## The end overlay earns its place because without it the fight has no visible ending: the
## loser just quietly stops.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")

@onready var hero: BattleUnit = %HeroGladiator
@onready var enemy: BattleUnit = %EnemyGladiator
@onready var damage_numbers: Node2D = %DamageNumbers
@onready var hero_nameplate: BattleNameplate = %HeroNameplate
@onready var enemy_nameplate: BattleNameplate = %EnemyNameplate
@onready var gladiator_match: GladiatorMatch = %GladiatorMatch


func _ready() -> void:
	GlobalSignalBus.unit_hurt.connect(_on_unit_hurt)
	hero_nameplate.setup(hero.stats)
	enemy_nameplate.setup(enemy.stats)
	gladiator_match.start()


func _on_unit_hurt(unit: Node2D, amount: int) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.setup(amount)
	# Position before adding: the number's _ready() reads its own position to seed the
	# drift animation, and _ready() fires the moment it enters the tree. The offset clears
	# the top of the art, which sits ~71px above the origin before the perspective scale.
	var spawn_at: Vector2 = unit.global_position + Vector2(-12.0, -90.0) * unit.scale
	number.position = damage_numbers.to_local(spawn_at)
	damage_numbers.add_child(number)
