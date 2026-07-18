class_name UnitStats
extends Resource
## Stat block for a BattleUnit, authored as data (.tres per unit).

@export var display_name: String = "Unit"
@export var level: int = 1
@export var max_health: int = 100
@export var max_stamina: int = 100
@export var damage: int = 10

## Attack rhythm. When left null the unit falls back to a steady one-beat loop built from
## attack_interval, so stat blocks written before patterns existed keep their original cadence.
@export var pattern: AttackPattern

## Seconds between attacks, used only as the fallback when pattern is null. Prefer authoring a
## pattern: it says the same thing as a one-beat loop and can also express shape.
@export var attack_interval: float = 1.5
## Stamina spent per attack. When a unit's stamina hits zero it attacks at half rate.
@export var stamina_cost: int = 10
@export var body_color: Color = Color(0.407, 0.756, 0.949)
