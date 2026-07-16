class_name BattleNameplate
extends PanelContainer
## Corner nameplate for one gladiator: name, level, HP bar and HP numbers.
## Seeds its static values from UnitStats, then tracks current health off the
## signal bus — it never holds a reference to the unit it renders.

@export var side: BattleUnit.Side = BattleUnit.Side.HERO
@export var show_hp_numbers: bool = true

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var hp_numbers: Label = %HpNumbers


func _ready() -> void:
	hp_numbers.visible = show_hp_numbers
	if side == BattleUnit.Side.HERO:
		GlobalSignalBus.hero_gladiator_health_changed.connect(_on_health_changed)
	else:
		GlobalSignalBus.enemy_gladiator_health_changed.connect(_on_health_changed)


func setup(stats: UnitStats) -> void:
	# Max health is seeded here rather than carried on the health_changed signal,
	# which also makes binding order-independent: the unit has already emitted its
	# initial health by the time the controller gets to call this.
	if stats == null:
		return
	name_label.text = stats.display_name
	level_label.text = "Lv.%d" % stats.level
	health_bar.max_value = stats.max_health
	_on_health_changed(stats.max_health)


func _on_health_changed(value: int) -> void:
	health_bar.value = value
	hp_numbers.text = "%d/%d" % [value, health_bar.max_value]
