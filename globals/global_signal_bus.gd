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
