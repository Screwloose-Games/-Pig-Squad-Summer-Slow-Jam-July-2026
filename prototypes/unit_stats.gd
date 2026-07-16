class_name UnitStats
extends Resource
## Stat block for a BattleUnit, authored as data (.tres per unit).

@export var display_name: String = "Unit"
@export var level: int = 1
@export var max_health: int = 100
@export var damage: int = 10
@export var attack_interval: float = 1.5
@export var body_color: Color = Color(0.407, 0.756, 0.949)
