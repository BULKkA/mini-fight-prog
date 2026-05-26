# mini-fight-prog — Codebase Overview (Godot 4.x, 2D)

## Summary
This is a small 2D melee arena game made in Godot 4. Player can move, dash, pick up weapons, and attack; enemies spawn in waves and use a simple navigation-based state machine (idle/chase/attack/return). Level selection is driven by data resources (`.tres` that contain JSON-like data) and a global `SpawnManager` autoload instantiates the chosen level plus entities.

A runtime error you reported occurs during weapon pickup: the player reparents a weapon node from the world into the player's `Inventory` from inside an `Area2D.area_entered` callback, which collides with Godot physics’ “flushing queries” rules.

## Architecture
**Primary architectural pattern:** scene orchestration via a global autoload + entity-level state machines.
- **Orchestration / boot flow**
  - `scenes/main/MainMenu.tscn` → `scripts/ui/main_menu.gd` handles level selection.
  - `scenes/main/LevelSelect.tscn` → `scripts/global/LevelManager.gd` lists levels and loads the selected scene + its data.
  - `scripts/global/SpawnManager.gd` (autoload) is responsible for spawning: player, enemies, weapons, and for caching the current level’s spawn points.
- **Entity logic**
  - Player logic is in `scripts/combat/player.gd` (movement + dash + attack loop + interact pickup).
  - Weapon pickup/attack logic is in `scripts/combat/weapon.gd` (animation, enable/disable attack hitboxes, apply damage/knockback, and pickup handling).
  - Enemy logic is in `scripts/combat/base_enemy.gd` (navigation-based chase, timed attack with enable/disable monitoring, knockback + stun on hit).

**Technology stack**
- Godot Engine 4.4.dev custom build
- GDScript 2D: `CharacterBody2D`, `Area2D`, `NavigationAgent2D`
- Resources: JSON-like `.tres` containers for level configs, enemy/weapon stats

**Execution entry point**
- `project.godot` sets `run/main_scene` to `MainMenu.tscn`.
- `MainMenu` only routes to level selection.
- `LevelSelect` runs `LevelManager.gd._ready()` to create buttons from `data/levels/Levels.tres`.
- When a button is pressed, `LevelManager` calls into `SpawnManager` to set the current level scene, spawn player, and start wave spawning.

## Directory Structure
```
project-root/
├── scripts/
│   ├── combat/
│   │   ├── player.gd        — player movement/dash/attack/pickup
│   │   ├── weapon.gd        — weapon animations + hitboxes + pickup
│   │   └── base_enemy.gd    — enemy AI/state machine + attack logic
│   ├── global/
│   │   ├── LevelManager.gd  — UI → load level scene + data → init runtime
│   │   └── SpawnManager.gd  — autoload: spawning waves/player/weapons
│   └── ui/
│       ├── health_bar.gd   — heart UI
│       └── main_menu.gd    — menu routing + quit
├── scenes/
│   ├── main/
│   │   ├── MainMenu.tscn
│   │   └── LevelSelect.tscn
│   ├── combat/
│   │   ├── Player.tscn
│   │   ├── weapon.tscn
│   │   └── BaseEnemy.tscn
│   └── arena/
│       └── TestArena.tscn
├── scenes/hud/
│   └── heart.tscn
├── data/
│   ├── Weapons.tres         — weapon stats
│   ├── Enemy.tres           — enemy stats
│   └── levels/
│       ├── Levels.tres     — list of levels
│       └── TestLevel/
│           └── TestLevel_Data.tres — per-level wave config
└── project.godot
```

## Key Abstractions

### Player
- **File**: `scripts/combat/player.gd`
- **Responsibility**: Handles player movement (including dash), attack direction/animation sequencing, health + death animation, and weapon pickup via `Interact`.
- **Interface (key parts)**
  - `_physics_process(delta)`: normal movement + dash control + chooses between `attack()` and `dash()`.
  - `attack()`: computes direction to mouse and awaits `currentWeapon.attack(direction)`.
  - `take_hit(amount, knockback)`: updates health, applies knockback impulses, triggers `die()` when health reaches 0.
  - `_on_interact_box_area_entered(area)`: calls `object.Interact(self)` where `object` is `area.get_parent()`.
  - `add_weapon(weapon)`: pushes weapon into an internal `weapons` list, reparents it under `Inventory`, positions it at `(0,0)`, and hides it.
- **Lifecycle**: spawned by `SpawnManager.SpawnPlayer()`, runs until death (`is_dead` stops physics updates).
- **Used by**:
  - `weapon.gd` calls `player.add_weapon(self)` in `Interact(in_player)`.
  - Enemies call `body.take_hit(...)` (player implements `take_hit`).

### Weapon (world pickup + active hitbox)
- **File**: `scripts/combat/weapon.gd`
- **Responsibility**: Stores weapon data/stats, handles attack animation + enabling/disabling a weapon-specific collision shape/polygon at timed intervals, applies damage/knockback to hit bodies, and supports being picked up.
- **Interface (key parts)**
  - `set_weapon_data(weapon_type, weapon_data, set_uses)`: saves stats, selects the weapon’s collision node by name (`weapon_type`), and initializes sprite/animation.
  - `attack(direction)`: decrements `uses`, rotates to direction, enables collision (`currentCollision.disable = false`), plays attack animation, disables collision afterward, and `queue_free()` when uses run out.
  - `Interact(in_player)`: sets `player = in_player` and calls `player.add_weapon(self)`.
- **Lifecycle**:
  - Spawned as a free-standing weapon scene by `SpawnManager.SpawnWeapon`.
  - On pickup, it is reparented under the player and made invisible (still exists and can be used for future attacks).
- **Used by**:
  - `player.gd` awaits `currentWeapon.attack(direction)`.
  - Player calls `weapon.gd.Interact()` via the InteractBox area callback.

### BaseEnemy (state machine + navigation)
- **File**: `scripts/combat/base_enemy.gd`
- **Responsibility**: Provides shared enemy behavior: idle/chase/attack/return state machine, navigation movement, timed attack hitbox enabling, knockback decay, health + death animation.
- **Interface (key parts)**
  - `_physics_process(delta)`: moves with `CharacterBody2D` + decays knockback; runs state machine; uses `move_and_slide()` at start of physics frame.
  - `set_state(new_state)`: central state transition helper.
  - `take_hit(amount, knockback)`: applies damage + knockback impulse and enters temporary `stun` animation sequence; calls `die()` when health hits 0.
  - `_perform_attack(AttackType)`: enables/disables attack area monitoring around timed animation windows.
  - `_on_visibility_area_area_entered`, `_on_body_area_area_entered/_exited`, `_on_exit_area_area_exited`: controls target acquisition/clearing and triggers state changes.
- **Lifecycle**: spawned by `SpawnManager.SpawnEnemy()` and dies by `queue`-free behavior implied via animation end (death handling calls `clothCollisions()`).
- **Used by**:
  - `weapon.gd` calls `body.take_hit(...)` on whatever collision triggers hit events (expects `take_hit` signature).

### LevelManager (data-driven level start)
- **File**: `scripts/global/LevelManager.gd`
- **Responsibility**: UI for selecting levels, then initializing runtime state with chosen scene and data (waves and spawn points).
- **Interface (key parts)**
  - `_ready()`: builds buttons from `data/levels/Levels.tres`.
  - `_on_level_pressed(level_id)`: reads the selected level entry and calls `OpenSceneWithData(level.link, level.level_data)`.
  - `OpenSceneWithData(Scene, Data)`: loads both the scene and its config, calls `InitializeScene(...)`, then changes the current scene.
  - `InitializeScene(scene, data)`: configures `SpawnManager` with the level and spawns player + starts waves.
- **Used by**: `LevelSelect.tscn`.

### SpawnManager (autoload spawner)
- **File**: `scripts/global/SpawnManager.gd`
- **Responsibility**: Global spawning logic: keeps current level scene reference, caches spawn points, instantiates player/enemies/weapons, and starts waves with `await create_timer(...).timeout`.
- **Interface (key parts)**
  - `setScene(Scene)`: caches `Level_SpawnPoints` from `currentScene.get_node("SpawnPoints")`.
  - `SpawnPlayer(position)`: instantiates `res://scenes/combat/Player.tscn`.
  - `SpawnEnemy(Enemy)`: instantiates an enemy based on stats in `data/Enemy.tres` and its `Link`.
  - `SpawnWeapon(Weapon)`: instantiates `res://scenes/combat/Weapon.tscn`, calls `weapon.set_weapon_data(...)`, places at a random spawn point, and `add_child(weapon)` to the current scene.
  - `StartWaves(waves_count, Waves)`: runs enemy spawns first for the first wave, then weapon spawns for that wave, each delayed by per-entry `spawn_delay`.
- **Used by**:
  - `LevelManager.gd` for initialization and wave start.

### HealthBar (hearts UI)
- **File**: `scripts/ui/health_bar.gd`
- **Responsibility**: Creates heart instances based on max health and updates the visible hearts when health changes.
- **Interface (key parts)**
  - `create_hearts(current_health)`: instantiates `heart_scene` `current_health` times and populates `hearts[]`.
  - `update_hearts(current_health)`: calculates how many child nodes to remove via `queue_free()`.

## Data Flow

1. **Boot / level selection**
   1) `MainMenu` → `_on_start_pressed()` changes scene to `LevelSelect.tscn`.
   2) `LevelSelect` runs `LevelManager._ready()`: reads `data/levels/Levels.tres`, creates buttons.
   3) Button press calls `LevelManager._on_level_pressed(level_id)` → `OpenSceneWithData(link, level_data)`.

2. **Runtime initialization**
   1) `LevelManager.InitializeScene(scene, data)` calls `SpawnManager.setScene(scene.instantiate())`.
   2) It calls `SpawnManager.SpawnPlayer(data.player_spawn_position)`.
   3) It calls `SpawnManager.StartWaves(data.waves_count, data.waves)`.

3. **Wave spawning**
   1) `SpawnManager.StartWaves(...)` currently selects `firstWave = Waves[0]`.
   2) It spawns enemies from `firstWave.enemies`, awaiting `enemy.spawn_delay` between spawns.
   3) It spawns weapons from `firstWave.weapons`, awaiting `weapons.spawn_delay` between spawns.

4. **Player weapon pickup**
   1) Player’s `InteractBox` emits `area_entered`.
   2) `_on_interact_box_area_entered(area)` gets `object = area.get_parent()` and calls `object.Interact(self)`.
   3) In `weapon.gd`, `Interact(in_player)` stores `player = in_player` and calls `player.add_weapon(self)`.
   4) `player.add_weapon(weapon)` reparents the weapon node under `Player/Inventory`, positions it at `(0,0)`, and hides it.

5. **Attacking**
   1) Player’s `attack()` computes mouse direction and awaits `currentWeapon.attack(direction)`.
   2) `weapon.gd.attack(direction)` rotates the weapon, plays attack animation, enables the currently selected collision polygon node only during the window, then disables it.
   3) Collision events call `attackBody(area.get_parent())`, which builds `knockback` and calls `body.take_hit(damage, knockback)`.

6. **Enemy attacking / hit response**
   1) Enemy attack logic `_perform_attack(AttackType)` enables monitoring on an `Area2D` window.
   2) On `take_hit(...)`, enemy health decreases, knockback impulse is applied, and if not dead it enters `stun` until animation finishes.

## Non-Obvious Behaviors & Design Decisions

### 1) Pickup happens inside a physics callback; reparenting can violate physics-server flushing rules
Your error:
- `player.gd:181 @ add_weapon(): Can't change this state while flushing queries. Use call_deferred() or set_deferred()...`
- Condition relates to `area_set_shape_disabled()` inside the physics server.

**What’s happening conceptually:**
- The pickup is triggered by `Area2D.area_entered` (`Player._on_interact_box_area_entered`).
- From inside that callback, `weapon.Interact()` runs, which immediately calls `player.add_weapon(self)`.
- `add_weapon()` performs `weapon.reparent(Inventory)` and changes visibility.
- Reparenting and/or the weapon’s internal Area2D/collision setup can cause Godot to adjust monitoring/shape state while the physics engine is in the middle of processing and flushing queries.

**Why it matters:**
- Godot 4 expects physics-related state changes (especially those affecting `Area2D` query/monitoring or collision shapes) to be deferred if you’re currently inside query processing.
- That’s why the error suggests `call_deferred()` / `set_deferred()` for monitoring-state changes.

**Code-level hotspot:**
- `scripts/combat/player.gd`: `add_weapon()` line with `weapon.reparent(Inventory)`
- Trigger chain:
  - `player._on_interact_box_area_entered()` → `object.Interact(self)`
  - `weapon.Interact()` → `player.add_weapon(self)` → `weapon.reparent(Inventory)`

### 2) Enemy hitbox enabling uses `Area2D.monitoring` toggling
Enemy attacks don’t enable/disable collision shapes by calling `disable` on polygons like the player’s weapon does. Instead, base enemy toggles:
- `AttackType.area.monitoring = true/false` in `_perform_attack`.

This avoids the same “area_entered callback context” timing as the pickup.

### 3) `SpawnManager` caches spawn points from `currentScene` that may not match what becomes the active scene
`LevelManager.InitializeScene` calls:
- `SpawnManager.setScene(scene.instantiate())`
- then changes the tree to `change_scene_to_packed(new_scene)` (where `new_scene` is loaded from disk).

So `SpawnManager` may be caching spawn points from a different instance than the one Godot becomes active. If node paths match you won’t notice, but it’s a fragility.

### 4) Current wave spawning is effectively “first wave only”
`SpawnManager.StartWaves` takes `waves_count` but uses only `firstWave = Waves[0]`.

### 5) Player assumes a weapon exists before attacking
`Player.attack()` directly calls `await currentWeapon.attack(direction)` without a guard.

## Module Reference

| File | Purpose |
|---|---|
| `scripts/global/LevelManager.gd` | Builds level selection UI and initializes selected level + wave data |
| `scripts/global/SpawnManager.gd` | Autoload spawner: caches level spawn points, spawns player/enemies/weapons, runs wave timers |
| `scripts/combat/player.gd` | Player movement/dash/attack + pickup interact handling and health/death |
| `scripts/combat/weapon.gd` | Weapon data, attack animation timing, hitbox enabling, apply damage/knockback, and pickup |
| `scripts/combat/base_enemy.gd` | Enemy state machine with navigation, timed attack monitoring, stun/knockback, death |
| `scripts/ui/health_bar.gd` | Heart UI creation and update |

## Suggested Reading Order
1. `scripts/global/LevelManager.gd`
2. `scripts/global/SpawnManager.gd`
3. `scripts/combat/player.gd` (especially pickup → physics-server error)
4. `scripts/combat/weapon.gd`
5. `scripts/combat/base_enemy.gd`
6. `scripts/ui/health_bar.gd`

## Notes on the specific error you saw (pickup reparent)
- **Most likely immediate cause:** calling `weapon.reparent(Inventory)` during `Area2D.area_entered` callback leads Godot physics to attempt collision/shape state changes while it is flushing queries.
- **Correct conceptual fix:** defer the pickup actions to a safe time using `call_deferred()` / `set_deferred()` (e.g., defer `reparent`, or defer the whole pickup handler to the next frame).