extends Node2D
## gladiator-with-junk copy but with enemy variants
##
## Rogue is fragile and opens with a fast 1-2 before a long gap, slugger is slow and enormous,
## gladiator is the balanced middle and ports the old enemy_stats.tres numbers exactly, so it
## is the baseline the other two should be judged against.
##
## The archetypes differ only in data — the three UnitStats resources in prototypes/variants/.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")

## Gap in pixels between the top of a gladiator's art and the bottom of its nameplate.
const NAMEPLATE_GAP: float = 8.0

## Uniform overhead width for both nameplates. The component is authored 460px wide for a
## screen corner; overhead it needs to be compact, but still wide enough to give the HP bar
## room (the bar collapses toward zero width if left to the content minimum).
const NAMEPLATE_WIDTH: float = 240.0

## Cycles the enemy to the next archetype and restarts the fight. A raw keycode rather than an
## input action because project.godot defines only `pause`, and a debug affordance in a
## prototype has no business editing shared project config.
const CYCLE_VARIANT_KEY: Key = KEY_V

## The archetypes to cycle through, in order. The enemy starts as the first.
@export var variants: Array[UnitStats]

var _battle_over: bool = false
var _variant_index: int = 0

@onready var hero: BattleUnit = %HeroGladiator
@onready var enemy: BattleUnit = %EnemyGladiator
@onready var damage_numbers: Node2D = %DamageNumbers
@onready var hero_nameplate: BattleNameplate = %HeroNameplate
@onready var enemy_nameplate: BattleNameplate = %EnemyNameplate
@onready var end_overlay: BattleEndOverlay = %BattleEndOverlay


func _ready() -> void:
	hero.setup(enemy)
	enemy.setup(hero)
	GlobalSignalBus.unit_hurt.connect(_on_unit_hurt)
	GlobalSignalBus.unit_died.connect(_on_unit_died)
	_start_fight()


func _process(_delta: float) -> void:
	_place_nameplate(hero_nameplate, hero)
	_place_nameplate(enemy_nameplate, enemy)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if (event as InputEventKey).keycode == CYCLE_VARIANT_KEY and not variants.is_empty():
			_variant_index = (_variant_index + 1) % variants.size()
			_start_fight()
			get_viewport().set_input_as_handled()


## Puts both gladiators back to full and starts them swinging, with the enemy wearing the
## current archetype. Also the first-run path, so opening the scene and cycling into a variant
## go through exactly the same code and cannot drift apart.
func _start_fight() -> void:
	_battle_over = false
	end_overlay.hide_result()
	hero.reset_for_new_fight()
	# The enemy's stats have to be re-applied rather than set in the editor: _apply_stats() runs
	# during BattleUnit._ready(), which for an editor-placed node has already happened by now.
	enemy.reset_for_new_fight(_current_variant())
	hero_nameplate.setup(hero.stats)
	enemy_nameplate.setup(enemy.stats)
	hero.start_fighting()
	enemy.start_fighting()


func _current_variant() -> UnitStats:
	if variants.is_empty():
		push_warning("EnemyVariants has no variants; the enemy keeps its scene-assigned stats.")
		return null
	return variants[_variant_index]


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
