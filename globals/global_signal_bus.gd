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
signal hero_gladiator_stamina_changed(value: int)
signal enemy_gladiator_hurt(value: int)
signal enemy_gladiator_health_changed(value: int)
signal enemy_gladiator_stamina_changed(value: int)

# combat — swing and strike detail. unit_attacked says a swing happened; these say what
# kind, which is what separates a sword from a fist and a fresh fighter from a spent one.
signal unit_swing(unit: Node2D, armed: bool, exhausted: bool)
signal unit_strike_landed(attacker: Node2D, target: Node2D, armed: bool)
signal unit_strike_whiffed(attacker: Node2D)
## The same hit unit_hurt reports, plus whether armor was in the way. `armored` with an
## amount of 0 is a hit the armor cancelled outright.
signal unit_damage_resolved(unit: Node2D, amount: int, armored: bool)

# combat — state crossings. Each of these fires on the edge, not while the state holds,
# so a listener can start and stop a sustained response cleanly.
signal unit_health_low(unit: Node2D)
signal unit_healed(unit: Node2D, amount: int)
signal unit_heal_wasted(unit: Node2D)
signal unit_stamina_restored(unit: Node2D, amount: int)
signal unit_stamina_depleted(unit: Node2D)
signal unit_stamina_recovered(unit: Node2D)

# combat — per-side deaths, alongside unit_died. Zero-argument on purpose: a listener that
# only cares which gladiator fell needs no reference to the node that fell.
signal hero_gladiator_died
signal enemy_gladiator_died

# match
## The first damage of the match, once. Every hit after it is just unit_hurt.
signal match_first_blood
## The result panel is actually on screen — later than battle_ended, and never emitted for
## a reveal that was cancelled while it waited.
signal match_result_revealed(hero_won: bool)

# equipment. Slot alone cannot tell a weapon from a helmet, so these carry the def and let
# the listener read WeaponDef vs ArmorDef off item_def.equipment.
signal unit_equipped(unit: Node2D, slot: EquipmentDef.Slot, item_def: ItemDef, replaced: bool)
signal unit_equipment_nearly_broken(unit: Node2D, slot: EquipmentDef.Slot, item_def: ItemDef)
signal unit_equipment_broke(unit: Node2D, slot: EquipmentDef.Slot, item_def: ItemDef)
## A swap threw the displaced piece back into the arena.
signal equipment_piece_popped(item: Node2D)

# items
signal item_spawned(item_def: ItemDef)
signal item_drag_started(item: Node2D)
signal item_drag_ended(item: Node2D)
signal item_hover_target_entered(item: Node2D, unit: Node2D)
signal item_hover_target_lost(item: Node2D)
## Released on a gladiator that cannot use this item — the player aimed and was refused.
signal item_drop_rejected(item: Node2D, unit: Node2D)
## Released on nothing in particular, which is usually deliberate.
signal item_drop_ignored(item: Node2D)
signal item_consumed(item_def: ItemDef, unit: Node2D)

# hotbar
signal hotbar_slot_filled(slot_number: int, item: Node2D)
signal hotbar_slot_replaced(slot_number: int, item: Node2D)
signal hotbar_item_removed(slot_number: int)
signal hotbar_slot_used(slot_number: int)
signal hotbar_use_failed(reason: HotbarUseFailure)

## Why a hotbar key press did nothing. Carried by hotbar_use_failed so a listener can tell
## "that slot is empty" from "the match is already lost".
enum HotbarUseFailure { EMPTY_SLOT, HERO_DEAD }
