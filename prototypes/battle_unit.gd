class_name BattleUnit
extends Node2D
## A stationary auto-battle unit that attacks its target on a timer.
## Every attack hits automatically — no collision detection. Damage is
## applied by the attack animation's method track at the lunge apex.

## Which gladiator this is. Picks the per-side signals emitted on the bus, so
## UI can listen for one fighter without holding a reference to it.
enum Side { HERO, ENEMY }

@export var stats: UnitStats
@export var side: BattleUnit.Side = BattleUnit.Side.HERO
@export var facing_left: bool = false
@export var flash_duration: float = 0.08
@export var shake_amplitude: float = 5.0
@export var shake_duration: float = 0.15
## Thickness (in texels) of the drop-target outline set_outline draws around the sprite.
## Texels, not pixels: the gladiator art renders at roughly two-thirds texture scale,
## so this reads about half as wide on screen.
@export var outline_width: float = 12.0

var target: BattleUnit

var _flash_tween: Tween
var _shake_tween: Tween

@onready var visuals: Node2D = %Visuals
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var health_component: HealthComponent = %HealthComponent
@onready var stamina_component: StaminaComponent = %StaminaComponent
@onready var attack_timer: Timer = %AttackTimer
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_apply_stats()
	visuals.scale.x = -1.0 if facing_left else 1.0
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	stamina_component.stamina_changed.connect(_on_stamina_changed)
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
	_emit_hurt(amount)
	if is_alive():
		_play_hit_react()


func is_alive() -> bool:
	return health_component.is_alive()


func _apply_stats() -> void:
	if stats == null:
		return
	# Team tint rides on modulate; the death animation fades self_modulate, so the
	# two multiply together instead of one clobbering the other.
	sprite.modulate = stats.body_color
	attack_timer.wait_time = stats.attack_interval
	health_component.initialize(stats.max_health)
	stamina_component.initialize(stats.max_stamina)


func _emit_hurt(amount: int) -> void:
	if side == Side.HERO:
		GlobalSignalBus.hero_gladiator_hurt.emit(amount)
	else:
		GlobalSignalBus.enemy_gladiator_hurt.emit(amount)


func _on_health_changed(current_health: int, _max_health: int) -> void:
	if side == Side.HERO:
		GlobalSignalBus.hero_gladiator_health_changed.emit(current_health)
	else:
		GlobalSignalBus.enemy_gladiator_health_changed.emit(current_health)


func _on_stamina_changed(current_stamina: int, _max_stamina: int) -> void:
	if side == Side.HERO:
		GlobalSignalBus.hero_gladiator_stamina_changed.emit(current_stamina)
	else:
		GlobalSignalBus.enemy_gladiator_stamina_changed.emit(current_stamina)


func _play_hit_react() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
		_clear_flash()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		visuals.position = Vector2.ZERO
	sprite.material.set_shader_parameter(&"flash_amount", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(flash_duration)
	_flash_tween.tween_callback(_clear_flash)
	_shake_tween = create_tween()
	var step_time: float = shake_duration / 4.0
	for i in 3:
		var offset := Vector2(
			randf_range(-shake_amplitude, shake_amplitude),
			randf_range(-shake_amplitude, shake_amplitude)
		)
		_shake_tween.tween_property(visuals, "position", offset, step_time)
	_shake_tween.tween_property(visuals, "position", Vector2.ZERO, step_time)


func _clear_flash() -> void:
	sprite.material.set_shader_parameter(&"flash_amount", 0.0)


## Shows/hides an outline around the sprite's silhouette. Used as the hover highlight
## while a usable item is dragged over this unit; safe alongside the hit flash because
## the material is local to each scene instance.
func set_outline(enabled: bool) -> void:
	sprite.material.set_shader_parameter(&"outline_width", outline_width if enabled else 0.0)


func _on_attack_timer_timeout() -> void:
	if not is_alive() or target == null or not target.is_alive():
		return
	stamina_component.consume(stats.stamina_cost)
	# Out of stamina → attack at half rate (double the interval). This is a repeating timer,
	# so it takes effect from the next cycle: the attack that drains stamina to zero still
	# fires at normal cadence, and the ones after it are slowed.
	var rate_factor: float = 2.0 if not stamina_component.has_stamina() else 1.0
	attack_timer.wait_time = stats.attack_interval * rate_factor
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
