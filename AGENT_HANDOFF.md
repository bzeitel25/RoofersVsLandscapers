# 🤖 AGENT BATON PASS & PROJECT STATE
**Project:** Roofers vs Landscapers
**Engine:** Godot 4.x
**Genre:** 10v10 Third-Person Shooter (TPS) Class-Based Combat

*Any AI agent joining this project should read this document first to understand the architecture, strict engine rules, and current progress. Update the "Recent Changes" section when you complete a task!*

---

## 🏗️ Core Architecture
1. **Player Controller (`player_character.gd`):** 
   * A `CharacterBody3D` with a Warframe-style over-the-shoulder TPS camera.
   * `C` key swaps the camera shoulder. 
   * The character's mesh is dynamically rotated to face the crosshair (`-Z`) using `Basis.looking_at()`.

2. **Weapon System (`base_tool.gd`, `base_melee.gd`, `base_projectile.gd`):**
   * Weapons are `RigidBody3D` nodes so they can be physically dropped into the world.
   * When held, they are parented to a `HandAttachment` (Node3D) on the character mesh.

3. **Loadout Manager (`loadout_manager.gd`):**
   * Manages 3 inventory slots per player: **0: Melee**, **1: Ranged**, **2: Gadget**.
   * Keys `1`, `2`, and `3` swap between these.

4. **Team Manager (`team_manager.gd`):**
   * Autoload Singleton defining 20 unique classes (10 Roofers, 10 Landscapers) and team specific shader/UI colors.

---

## ⚠️ CRITICAL GODOT 4 RULES (DO NOT BREAK)
* **Coordinate System:** Forward is `-Z`. When building weapons, group meshes inside a `visual_root` (Node3D) and rotate them so they point along the `-Z` axis when held. For weapons built "up" along the Y axis, set `visual_root.rotation_degrees.x = -90`.
* **Physics & Scaling:** **NEVER scale a `RigidBody3D` directly** (e.g., `scale = Vector3(...)`). It destroys Godot's physics solver and corrupts the matrix. Scale the meshes inside it instead.
* **Freeze Mode Bug:** In Godot 4, a frozen `RigidBody3D` with a `CollisionShape3D` will act as a static wall and refuse to follow its parent unless you explicitly set its `freeze_mode` to `RigidBody3D.FREEZE_MODE_KINEMATIC`. This is handled inside `_set_physical_state(false)` in `base_tool.gd`.

---

## 🕒 Current State & Recent Changes (Aug 2026)
* **Camera System:** Fully transitioned from FPS to an over-the-shoulder TPS.
* **Physics Fixes:** Fixed severe weapon rendering bugs caused by scaling and static physics pinning.
* **Roster Expansion:** Automatically generated all 60 weapons (Melee, Ranged, Gadgets) for the full 20-character roster. Every single class now auto-equips their specific 3 items when chosen from the `test_level.tscn` Training UI.
* **Weapon Differentiation:** Heavy weapons (Axes, Hammers) have slow, wide arcs. Light weapons (Shivs, Pruners) have fast thrusting stabs.

---

## 🚀 Next Steps / To-Do
1. **Multiplayer Sync:** Implement Godot networking (ENet) to sync player positions, animations, and projectiles across clients.
2. **Vehicles:** Build the "Big Tony's Rocket Mower" D.Va-style pilotable vehicle mechanic.
3. **Assets:** Replace the primitive CSG placeholder weapon blocks with actual 3D `.glb` / `.gltf` assets.
4. **UI:** Add a dedicated crosshair and on-screen cooldown timers for abilities.

---
*End of Document. Next Agent: Please append your changes to "Recent Changes" when finishing your session.*
