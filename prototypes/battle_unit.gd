class_name BattleUnit
extends Node2D
## A stationary auto-battle unit that attacks its target on a timer.
## Every attack hits automatically — no collision detection. Damage is
## applied by the attack animation's method track at the lunge apex.

@export var stats: UnitStats
@export var facing_left: bool = false
@export var flash_duration: float = 0.08
@export var shake_amplitude: float = 5.0
@export var shake_duration: float = 0.15

var target: BattleUnit

var _base_colors: Dictionary = {}
var _flash_tween: Tween
var _shake_tween: Tween

@onready var visuals: Node2D = %Visuals
@onready var body: Polygon2D = %Body
@onready var head: Polygon2D = %Head
@onready var weapon: Polygon2D = %Weapon
@onready var health_component: HealthComponent = %HealthComponent
@onready var attack_timer: Timer = %AttackTimer
@onready var health_bar: ProgressBar = %HealthBar
@onready var name_label: Label = %NameLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_apply_stats()
	visuals.scale.x = -1.0 if facing_left else 1.0
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	health_component.died.connect(_on_died)
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("idle_bob")


func setup(new_target: BattleUnit) -> void:
	target = new_target


func start_fighting() -> void:
	attack_timer.start()


func stop_fighting() -> void:
	attack_timer.stop()


func take_damage(amount: int) -> void:
	if not is_alive():
		return
	health_component.take_damage(amount)
	GlobalSignalBus.unit_hurt.emit(self, amount)
	if is_alive():
		_play_hit_react()


func is_alive() -> bool:
	return health_component.is_alive()


func _apply_stats() -> void:
	if stats == null:
		return
	body.color = stats.body_color
	head.color = stats.body_color.lightened(0.3)
	name_label.text = stats.display_name
	attack_timer.wait_time = stats.attack_interval
	health_bar.bind_health(health_component)
	health_component.initialize(stats.max_health)
	_base_colors = {body: body.color, head: head.color, weapon: weapon.color}


func _play_hit_react() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
		_restore_colors()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		visuals.position = Vector2.ZERO
	for polygon: Polygon2D in _base_colors:
		polygon.color = Color.WHITE
	_flash_tween = create_tween()
	_flash_tween.tween_interval(flash_duration)
	_flash_tween.tween_callback(_restore_colors)
	_shake_tween = create_tween()
	var step_time: float = shake_duration / 4.0
	for i in 3:
		var offset := Vector2(
			randf_range(-shake_amplitude, shake_amplitude),
			randf_range(-shake_amplitude, shake_amplitude)
		)
		_shake_tween.tween_property(visuals, "position", offset, step_time)
	_shake_tween.tween_property(visuals, "position", Vector2.ZERO, step_time)


func _restore_colors() -> void:
	for polygon: Polygon2D in _base_colors:
		polygon.color = _base_colors[polygon]


func _on_attack_timer_timeout() -> void:
	if not is_alive() or target == null or not target.is_alive():
		return
	animation_player.play("attack")
	GlobalSignalBus.unit_attacked.emit(self, target)


func _on_attack_strike() -> void:
	# Called by the attack animation's method track at the lunge apex.
	if not is_alive() or target == null or not target.is_alive():
		return
	target.take_damage(stats.damage)


func _on_died() -> void:
	stop_fighting()
	animation_player.play("death")
	GlobalSignalBus.unit_died.emit(self)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"attack" and is_alive():
		animation_player.play("idle_bob")
