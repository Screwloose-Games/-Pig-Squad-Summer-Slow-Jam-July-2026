class_name AttackPattern
extends Resource
## An attack rhythm, authored as a looping timeline: a BattleUnit scrubs a playhead along it
## and swings each time the playhead crosses a beat.
##
## A timeline rather than a plain interval because an interval can only say "every N seconds",
## and archetypes want shape — a rogue's quick 1-2 followed by a gap is two beats bunched at the
## head of a long loop. It also gives stamina somewhere natural to land: slowing a unit scales
## the playhead's speed, which stretches the whole rhythm uniformly instead of special-casing
## one number.
##
## This is pure data and holds no playhead, because one pattern resource is shared by every unit
## that uses it. The playhead lives on the unit.

## Loop length in seconds. The playhead wraps here, so this is the gap from the last beat back
## around to the first.
@export var duration: float = 1.5

## Offsets in seconds within the loop where an attack starts. Must be sorted ascending and stay
## below duration; BattleUnit walks them in order and does not re-sort.
##
## A beat starts the attack animation — it is not the moment damage lands. The animation's method
## track strikes 0.25s in, so the hit reads slightly after the beat. That animation is 0.5s long,
## which bounds how tightly beats can be packed: closer than 0.5s visibly restarts the swing
## mid-recovery (fine, and how a burst is meant to look), but closer than 0.25s cuts the previous
## swing before it strikes and silently drops that attack.
@export var beats: Array[float] = [0.0]
