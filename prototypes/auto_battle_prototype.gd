extends Node2D
## Auto-battle prototype controller: wires the two units to each other,
## spawns floating damage numbers and plays hit sounds. Units know nothing about
## audio or UI, and the end overlay shows itself off battle_ended, so this only has
## to call the fight.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")
const HIT_SOUND: AudioStream = preload("res://common/audio/sfx/ui/UI_CLICK.wav")

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
	GlobalSignalBus.level_started.emit()
	hero.start_fighting()
	enemy.start_fighting()


func _on_unit_hurt(unit: Node2D, amount: int) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.setup(amount)
	# Position before adding: the number's _ready() reads its own position to seed
	# the drift animation, and _ready() fires the moment it enters the tree.
	# Offset clears the top of the art, which sits ~71px above the origin before
	# the unit's perspective scale is applied.
	var spawn_at: Vector2 = unit.global_position + Vector2(-12.0, -90.0) * unit.scale
	number.position = damage_numbers.to_local(spawn_at)
	damage_numbers.add_child(number)
	SoundManager.play_sound(HIT_SOUND, GSoundManager.SoundPlayerType.UI)


func _on_unit_died(unit: Node2D) -> void:
	if _battle_over:
		return
	_battle_over = true
	hero.stop_fighting()
	enemy.stop_fighting()
	# BattleEndOverlay picks this up off the bus and handles its own reveal and restart.
	GlobalSignalBus.battle_ended.emit(unit == enemy)
