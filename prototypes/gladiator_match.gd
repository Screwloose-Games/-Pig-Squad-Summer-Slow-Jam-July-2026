class_name GladiatorMatch
extends Node
## One match between two teams of gladiators.
##
## Owns the fight lifecycle so no scene has to: it assigns each combatant a target, starts
## them swinging, latches first blood, watches for deaths, and declares a winner. A match is
## over when every combatant on a team is dead — not when the first one falls, which is what
## the scene scripts used to assume and what made a second fighter per side impossible.
##
## Nothing here holds a reference to the scene it sits in. Drop the node into any combat
## scene, point the two team arrays at the gladiators, and call start().

## Fired before the combatants start swinging. The bus-wide match_started goes out at the
## same moment; this one is for anything wired directly to this match.
signal gladiator_match_started
## Fired the instant a team is wiped, ahead of the bus-wide battle_ended.
signal gladiator_match_ended(hero_won: bool)

@export var hero_team: Array[BattleUnit] = []
@export var enemy_team: Array[BattleUnit] = []
## Also announce this match on GlobalSignalBus, which is where the audio hooks and the end
## overlay listen. Turn off for a second match running alongside the real one, so a
## background skirmish cannot fire the go-signal or end the player's fight.
@export var emit_global_signals: bool = true

var _running: bool = false
## Latches match_first_blood: unit_hurt fires on every hit, but the moment the staredown
## becomes a fight happens once per match.
var _first_blood_done: bool = false


func _ready() -> void:
	# Connected once, for the life of the node. The handlers filter by _running, so a match
	# that has not started (or has already been decided) ignores the traffic.
	GlobalSignalBus.unit_hurt.connect(_on_unit_hurt)
	GlobalSignalBus.unit_died.connect(_on_unit_died)


## Puts the match on. Deliberately not called from _ready(): the scene decides when, because
## resetting units and seeding nameplates has to happen first. Safe to call again to run a
## fresh match with the same node — enemy-variants restarts this way.
func start() -> void:
	if hero_team.is_empty() or enemy_team.is_empty():
		push_warning("GladiatorMatch needs a combatant on each team; not starting.")
		return
	_running = true
	_first_blood_done = false
	_assign_targets()
	gladiator_match_started.emit()
	if emit_global_signals:
		GlobalSignalBus.match_started.emit()
	for unit in combatants():
		unit.start_fighting()


## Stops everyone swinging without declaring a result. For tearing a match down or cycling
## away from one mid-fight; _finish() calls it too, after the winner is known.
func stop() -> void:
	_running = false
	for unit in combatants():
		unit.stop_fighting()


func is_running() -> bool:
	return _running


func is_team_alive(team: Array[BattleUnit]) -> bool:
	for unit in team:
		if unit != null and unit.is_alive():
			return true
	return false


## Every combatant in the match, both teams, with empty team slots filtered out.
func combatants() -> Array[BattleUnit]:
	var all: Array[BattleUnit] = []
	for unit in hero_team + enemy_team:
		if unit != null:
			all.append(unit)
	return all


## The team this unit fights, or an empty array if it is not in this match at all.
func opposing_team_of(unit: BattleUnit) -> Array[BattleUnit]:
	if hero_team.has(unit):
		return enemy_team
	if enemy_team.has(unit):
		return hero_team
	return []


func _assign_targets() -> void:
	for unit in combatants():
		if unit.is_alive():
			unit.setup(_pick_target(unit))


## Pairs off by index against the opposing team, wrapping when the teams are uneven, so
## everyone has someone to hit and a lone defender takes on the whole line. Dead opponents
## are skipped, which is what lets a survivor pick up a new target mid-match.
func _pick_target(unit: BattleUnit) -> BattleUnit:
	var opponents: Array[BattleUnit] = opposing_team_of(unit)
	var living: Array[BattleUnit] = []
	for opponent in opponents:
		if opponent != null and opponent.is_alive():
			living.append(opponent)
	if living.is_empty():
		return null
	var own_team: Array[BattleUnit] = hero_team if hero_team.has(unit) else enemy_team
	return living[own_team.find(unit) % living.size()]


func _on_unit_hurt(unit: Node2D, _amount: int) -> void:
	if not _running or _first_blood_done:
		return
	if not combatants().has(unit):
		return
	_first_blood_done = true
	if emit_global_signals:
		GlobalSignalBus.match_first_blood.emit()


func _on_unit_died(unit: Node2D) -> void:
	if not _running or not combatants().has(unit):
		return
	# Before the win check, so survivors whose opponent just fell swing at whoever is left
	# rather than standing there with a dead target.
	_assign_targets()
	# Hero first: with both teams emptied on the same frame, the one that emptied first is
	# the one that lost, and battle_ended's bool has no way to say "draw".
	if not is_team_alive(hero_team):
		_finish(false)
	elif not is_team_alive(enemy_team):
		_finish(true)


func _finish(hero_won: bool) -> void:
	stop()
	gladiator_match_ended.emit(hero_won)
	if emit_global_signals:
		GlobalSignalBus.gladiator_match_ended.emit(hero_won)
		# Last: BattleEndOverlay starts its reveal off this one.
		GlobalSignalBus.battle_ended.emit(hero_won)
