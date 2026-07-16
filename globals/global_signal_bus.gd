extends Node

# levels / menus
signal changed_level
signal title_screen_started
signal credits_screen_started
signal level_started
signal level_reset
signal game_paused
signal game_unpaused

# UI
signal ui_button_pressed
signal ui_button_hovered

# combat
signal unit_attacked(attacker: Node2D, target: Node2D)
signal unit_hurt(unit: Node2D, amount: int)
signal unit_died(unit: Node2D)
signal battle_ended(hero_won: bool)

# combat — per-gladiator, UI-facing. Plain values, no node refs: the listener
# already knows which gladiator it renders. Max health is static per unit, so
# it is seeded from UnitStats rather than carried on every change.
signal hero_gladiator_hurt(value: int)
signal hero_gladiator_health_changed(value: int)
signal enemy_gladiator_hurt(value: int)
signal enemy_gladiator_health_changed(value: int)
