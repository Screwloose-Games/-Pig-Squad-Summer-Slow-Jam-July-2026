# Gladdy Caddy

A Godot 4.7 game (auto-battler), built on a template adapted from
[Screwloose Games — solar-punk-jam](https://github.com/Screwloose-Games/solar-punk-jam).

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
