extends ProgressBar
## Mirrors a HealthComponent's health onto this progress bar.


func bind_health(component: HealthComponent) -> void:
	component.health_changed.connect(_on_health_changed)


func _on_health_changed(current_health: int, new_max_health: int) -> void:
	max_value = new_max_health
	value = current_health
