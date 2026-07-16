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
## Info nameplates and floating damage numbers are reused from the auto-battle prototype,
## but placed above each gladiator's head rather than in screen corners. The end overlay
## earns its place because without it the fight has no visible ending: the loser just
## quietly stops.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")

## Gap in pixels between the top of a gladiator's art and the bottom of its nameplate.
const NAMEPLATE_GAP: float = 8.0

## Uniform overhead width for both nameplates. The component is authored 460px wide for a
## screen corner; overhead it needs to be compact, but still wide enough to give the HP bar
## room (the bar collapses toward zero width if left to the content minimum).
const NAMEPLATE_WIDTH: float = 240.0

var _battle_over: bool = false

@onready var hero: BattleUnit = %HeroGladiator
@onready var enemy: BattleUnit = %EnemyGladiator
@onready var damage_numbers: Node2D = %DamageNumbers
@onready var hero_nameplate: BattleNameplate = %HeroNameplate
@onready var enemy_nameplate: BattleNameplate = %EnemyNameplate


func _ready() -> void:
	hero.setup(enemy)
	enemy.setup(hero)
	GlobalSignalBus.unit_hurt.connect(_on_unit_hurt)
	GlobalSignalBus.unit_died.connect(_on_unit_died)
	hero_nameplate.setup(hero.stats)
	enemy_nameplate.setup(enemy.stats)
	hero.start_fighting()
	enemy.start_fighting()


func _process(_delta: float) -> void:
	_place_nameplate(hero_nameplate, hero)
	_place_nameplate(enemy_nameplate, enemy)


func _on_unit_hurt(unit: Node2D, amount: int) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.setup(amount)
	# Position before adding: the number's _ready() reads its own position to seed the
	# drift animation, and _ready() fires the moment it enters the tree. The offset clears
	# the top of the art, which sits ~71px above the origin before the perspective scale.
	var spawn_at: Vector2 = unit.global_position + Vector2(-12.0, -90.0) * unit.scale
	number.position = damage_numbers.to_local(spawn_at)
	damage_numbers.add_child(number)


func _on_unit_died(unit: Node2D) -> void:
	if _battle_over:
		return
	_battle_over = true
	hero.stop_fighting()
	enemy.stop_fighting()
	# The overlay listens for this on the bus; it is not wired to this scene directly.
	GlobalSignalBus.battle_ended.emit(unit == enemy)


func _place_nameplate(plate: BattleNameplate, unit: BattleUnit) -> void:
	# Keep the plate a uniform readable size (not scaled by the unit's perspective scale),
	# centered horizontally over the head. Force the compact overhead width — free-floating,
	# it would otherwise keep the component's authored 460px corner-HUD width — and let the
	# height fit its content.
	plate.size = Vector2(NAMEPLATE_WIDTH, plate.get_combined_minimum_size().y)
	# The -90 * scale offset matches the damage numbers and clears the top of the art; the
	# plate's bottom sits a few px above that.
	var head_world: Vector2 = unit.global_position + Vector2(0.0, -90.0) * unit.scale
	var screen: Vector2 = get_viewport().get_canvas_transform() * head_world
	plate.position = screen - Vector2(plate.size.x * 0.5, plate.size.y + NAMEPLATE_GAP)
