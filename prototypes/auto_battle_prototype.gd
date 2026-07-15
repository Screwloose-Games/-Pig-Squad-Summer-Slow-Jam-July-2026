extends Node2D
## Auto-battle prototype controller: wires the two units to each other,
## spawns floating damage numbers, plays hit sounds, and shows the
## victory/defeat overlay. Units know nothing about audio or UI.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prototypes/damage_number.tscn")
const HIT_SOUND: AudioStream = preload("res://common/audio/sfx/ui/UI_CLICK.wav")
const DEATH_ANIM_WAIT: float = 0.8

var _battle_over: bool = false

@onready var hero: BattleUnit = %HeroGladiator
@onready var enemy: BattleUnit = %EnemyGladiator
@onready var damage_numbers: Node2D = %DamageNumbers
@onready var overlay_root: Control = %OverlayRoot
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	hero.setup(enemy)
	enemy.setup(hero)
	GlobalSignalBus.unit_hurt.connect(_on_unit_hurt)
	GlobalSignalBus.unit_died.connect(_on_unit_died)
	restart_button.pressed.connect(_on_restart_pressed)
	overlay_root.visible = false
	GlobalSignalBus.level_started.emit()
	hero.start_fighting()
	enemy.start_fighting()


func _on_unit_hurt(unit: Node2D, amount: int) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.setup(amount)
	damage_numbers.add_child(number)
	number.global_position = unit.global_position + Vector2(-12.0, -130.0)
	SoundManager.play_sound(HIT_SOUND, GSoundManager.SoundPlayerType.UI)


func _on_unit_died(unit: Node2D) -> void:
	if _battle_over:
		return
	_battle_over = true
	hero.stop_fighting()
	enemy.stop_fighting()
	var hero_won: bool = unit == enemy
	GlobalSignalBus.battle_ended.emit(hero_won)
	await get_tree().create_timer(DEATH_ANIM_WAIT).timeout
	result_label.text = "Victory!" if hero_won else "Defeat"
	overlay_root.visible = true


func _on_restart_pressed() -> void:
	GlobalSignalBus.ui_button_pressed.emit()
	get_tree().reload_current_scene()
