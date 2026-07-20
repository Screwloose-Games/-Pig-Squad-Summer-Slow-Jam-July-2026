class_name BattleNameplate
extends Control
## Corner nameplate for one gladiator: name, level, and layered HP/stamina bars.
## Seeds its static values from UnitStats, then tracks current health and stamina off the
## signal bus — it never holds a reference to the unit it renders.

@export var side: BattleUnit.Side = BattleUnit.Side.HERO
## Mirrors the backing panel and name plate for a right-corner block. The bars still fill
## left-to-right; only the frame art flips.
@export var mirrored: bool = false
## Retained so scenes that still assign it don't warn; the reskinned plate shows no numbers.
@export var show_hp_numbers: bool = true

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var stamina_bar: TextureProgressBar = %StaminaBar
@onready var _backing: TextureRect = %Backing
@onready var _name_plate: TextureRect = %NamePlate


func _ready() -> void:
	_backing.flip_h = mirrored
	_name_plate.flip_h = mirrored
	if side == BattleUnit.Side.HERO:
		GlobalSignalBus.hero_gladiator_health_changed.connect(_on_health_changed)
		GlobalSignalBus.hero_gladiator_stamina_changed.connect(_on_stamina_changed)
	else:
		GlobalSignalBus.enemy_gladiator_health_changed.connect(_on_health_changed)
		GlobalSignalBus.enemy_gladiator_stamina_changed.connect(_on_stamina_changed)


func setup(stats: UnitStats) -> void:
	# Max health is seeded here rather than carried on the health_changed signal, which also
	# makes binding order-independent: the unit has already emitted its initial health by the
	# time the controller gets to call this.
	if stats == null:
		return
	name_label.text = stats.display_name
	level_label.text = "Lv.%d" % stats.level
	health_bar.max_value = stats.max_health
	_on_health_changed(stats.max_health)
	stamina_bar.max_value = stats.max_stamina
	_on_stamina_changed(stats.max_stamina)
	if mirrored:
		health_bar.scale.y = -1
		stamina_bar.scale.y = -1
		stamina_bar.position.x -= 70


func _on_health_changed(value: int) -> void:
	health_bar.value = value


func _on_stamina_changed(value: int) -> void:
	stamina_bar.value = value
