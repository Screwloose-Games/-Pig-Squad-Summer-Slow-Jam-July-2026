extends Node2D
## Auto-battle prototype controller: spawns floating damage numbers and plays hit sounds.
## The fight itself belongs to the GladiatorMatch node — it pairs the units, starts them and
## calls the winner. Units know nothing about audio or UI, and the end overlay shows itself
## off battle_ended, so this only has to kick the match off.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")
const HIT_SOUND: AudioStream = preload("res://common/audio/sfx/ui/UI_CLICK.wav")

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
	# level_started says this scene is up, which level_01 says too; the match's own
	# match_started says a fight is beginning, and the go-signal audio hangs off that one.
	GlobalSignalBus.level_started.emit()
	gladiator_match.start()


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
