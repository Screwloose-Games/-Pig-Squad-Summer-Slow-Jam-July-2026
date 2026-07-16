# Gladdy Caddy

A frantic inventory-management auto-battler for the SummerSlow Jam.

**Theme:** Inventory · **Creative sub-theme:** Use it or lose it
**Deadline:** Monday (Sunday is the last full working day)
**Engine:** Godot

> *Working title. Alternatives ("Gladiator's Apprentice," etc.) may be put to a vote.*

---

## Concept

You are not the gladiator — you're the gladiator's assistant. Your hero fights automatically in a Pokémon-style side-by-side battle in a Roman coliseum, and it's your job to keep them alive and equipped.

- The hero's action-selection UI is visible but not controllable; low stamina slows the rate at which the hero picks actions
- The player manages the hero's **health, stamina, and equipment**
- Enemy gladiators have specialties (fast attacker, high endurance, etc.) that shape what resources your hero burns

## Core Loop

1. The crowd throws junk into the arena, forming piles
2. Dig through piles top-down — flick items aside to reach buried ones; flick trash off-screen
3. Manage a small inventory (~4-slot quick bar): give items to the hero immediately or save them for later
4. React to the fight state (hero taking damage → stockpile potions; heavy dodging → grab stamina items)

**Cut:** The enemy gladiator having its own assistant — visual set dressing at most.

## Art & Tech

- All gameplay assets are **2D** (3D item piles were considered and rejected)
- 3D is limited to non-gameplay juice only (e.g., a title screen), TBD
- Crowd/arena art is sliced into layers so crowd groups can bob independently
- Repo initialized with a V1 shell (main menu)

## Audio

- **Signal/event-bus architecture:** programmers emit named signals (e.g., `ui_hover`, `sword_attack`, `player_hit`); the audio system listens and plays the matching sound
- Sounds are tracked in a shared editable spreadsheet (signal name, context, description, stop events), based on a template from a prior project

## Team & Responsibilities

| Person | Role |
|---|---|
| Jonathan | Auto-battler logic, repo and signal planning |
| Steven | Physics-based rummaging prototype |
| Antic | 2D art — side-view item sketches, slicing arena into layers |
| Sean | Sound library, music, audio programming (event bus); 3D title screen later in the week |

**Fallback:** If physics rummaging doesn't pan out, switch to a discard-an-item-to-draw-a-random-one mechanic.

## Constraints

- **No AI-generated assets** (jam rule)
- Keep scope simple: few locations, simple mechanics

## Open Questions

- Final title
- Rock-paper-scissors weapon-counter mechanic (mace / dagger / sword & shield) — in or out?
- Music track count (one main track vs. adding menu/victory tracks)
- Whether the 3D title screen actually happens

## Project structure

```
common/
  audio/        Music + UI SFX (buses: Master, SFX, Music, Ambient, Dialogue)
  fonts/        UI font
  themes/       Global UI theme (theme.tres)
  ui/
    main_menu/          Main menu (main scene)
    options_menu/       Volume sliders + windowed/fullscreen toggle
    pause_menu/         In-game pause overlay (Esc / P)
    scene_transitions/  Fade + circle transitions
    screens/            Credits (auto-scrolls ATTRIBUTION.md)
globals/        Autoload singletons
  global_signal_bus.gd        App-wide signals
  scene_manager.gd            PackedScene registry (MAIN_LEVEL, MAIN_MENU, ...)
  scene_transition_manager.gd change_scene_with_transition(scene, transition)
  game_settings.tscn          Loads/saves settings to user://settings.tres
  sound_manager/              UI/ambient SFX players + signal-driven connectors
levels/
  level_01/     Placeholder first level (pause menu wired up)
```

## How things connect

- **Start game**: main menu → `SceneTransitionManager.change_scene_with_transition(SceneManager.MAIN_LEVEL, SceneManager.FADE_TRANSITION)`
- **Audio settings**: options menu sliders set `AudioServer` bus volumes and persist via the `GameSettings` autoload (`user://settings.tres`); reapplied on startup.
- **Pause**: `pause` input action (Esc or P) toggles the pause menu instanced in the level.
- **Credits**: renders `ATTRIBUTION.md` — edit that file to update the credits screen.
- **New levels**: add a scene under `levels/`, register it in `globals/scene_manager.gd`.

## Export

Renderer is GL Compatibility for web (itch.io) export.
