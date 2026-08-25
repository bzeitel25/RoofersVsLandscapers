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

### Multiplayer & Web
* **Multiplayer Sync:** Fully transitioned from ENet to a `WebSocketMultiplayerPeer` backend to support browser-compatible HTML5 web exports. Programmatic Host/Join lobby UI is active.

### Movement Archetypes & Parkour
* **Light Classes:** Double Jump, Base Speed 6.5, Sprint 1.8x. (Climber gets a unique Triple Jump and 10.0 jump force).
* **Medium Classes:** Single Jump, Base Speed 6.0, Sprint 1.4x.
* **Heavy Classes:** Single Jump, Base Speed 5.0, Sprint 1.3x.
* **Parkour Toolkit:** Added 3-raycast Ledge Vaulting, angled Roof Sliding (hold Crouch), and deployable physics Ziplines.

### UI & HUD (Aug 25 2026)
* **Player HUD:** Expanded lower-left UI includes `Ammo: X/Y` and `Supplies: 100` readouts positioned directly above the Health Bar.
* **Weapon Slots:** 3 colored boxes (Keys 1, 2, 3) sit to the left of the health bar showing the abbreviated names of the equipped Melee, Ranged, and Gadget. The active slot highlights blue.
* **Cooldowns:** Tools on cooldown display a yellow decimal countdown timer in the center of their respective slot box.
* **Resource Economy:** Gadgets consume the player's `supplies` pool (max 100). For example, the Foreman's shield costs 33 supplies, effectively granting 3 charges.

### Weapons & Synergies
* **Pneumatic Nail Gun (Nailer):** Primary sticks nails into targets. Alt-fire (Steady Aim) pulls FOV to 55 and slows movement to 65% for precision.
* **Pry Bar (Nailer):** Alt-fire triggers the *Nail Puller* synergy (rips out stuck nails for 15 bonus damage each) or the *Deconstructor* (deals 300% damage to instantly shatter gadgets).
* **Boss Hammer & Glass Shield (Foreman):** Gadget holds 3 shield charges that stack neatly on top of each other and snap to the floor. The Boss Hammer instantly shatters glass shields in a single hit.
* **Tar Gun (Tar King):** Primary shoots tar blobs applying a 60% movement slow. Alt-fire shoots an Ignite Flare. Hitting a tarred enemy consumes the tar and burns them for 16 DPS over 3 seconds.
* **Shingle Slinger:** TPS aiming applied. Alt-fire consumes 3 ammo for a horizontal 5-shingle shotgun fan.
* **Weed Wacker (Trimmer):** Continuous rapid-tick melee. Alt-fire consumes 5 gas for a violent 25m/s horizontal Over-rev dash (40 AoE damage at the end).
* **Felling Axe (Lumberjack):** Alt-fire is *TIMBER!*, a 2.5s overhead slam dealing 150% damage to players and 999 damage to fortifications.
* **Rocket Mower:** Big Tony's pilotable vehicle. Takes damage for the driver, explodes for 25% max HP blast damage on death.

### Test Arena — Suburban Cul-de-sac (Aug 25 2026)
* **First playable arena added:** `scenes/main/suburban_arena.tscn` (reuses `test_level.gd` for the training UI + the standard Player rig) driven by a new procedural generator `scripts/levels/suburban_arena.gd`.
* **Procedural & parametric** (@export knobs: house count/size, story height, roof pitch, fence height, cul-de-sac radius, seed). Generates a 5-house upper-class cul-de-sac.
* **Enterable 2-story houses** built for a spring-arm TPS: open-concept ground floor + double-height entry + partial mezzanine w/ vaultable railing, tall 4m ceilings, wide 3m+ doorways (keeps the SpringArm3D from clipping).
* **Parkour tuned to the controller:** 32 deg pitched roofs trigger roof-sliding; fences/planters/low walls/car roofs sit ~1.0-1.5m for vaulting; ridge-gap + hollow chimney + attic hatch give a roof -> attic -> interior infiltration route; functional `LadderObject` roof access (side + interior).
* **Full suburb dressing:** fenced yards, driveways w/ parked cars, trees/bushes/flowerbeds, brick murals, rock clusters, mailboxes, lawn ornaments (gnome/flamingo/birdbath), a central landscaped island, and a perimeter hedge boundary.
* Cars are tagged (`vehicles` + `hotwireable` groups, `set_meta("hotwireable", true)`) ready for the future hotwire/launch feature.
* All static geometry on **collision layer 1** (matches the player floor + vault raycast masks). No RigidBody scaling; houses built front-on-(-Z) then yaw-faced to the cul-de-sac. Parse- + runtime-validated in Godot 4.3 headless (0 script errors).

---

## 🚀 Next Steps / To-Do
1. ~~**Level Design:** Suburban House Blockout to test parkour/traversal.~~ **DONE (Aug 25 2026)** -> `scenes/main/suburban_arena.tscn`. Open it in the editor to playtest and tune the generator's @export knobs.
2. **Camera (interiors):** Make the player `SpringArm3D` collision-aware / auto-shorten indoors so the 3rd-person camera never clips house walls. Arena interiors are built large to mitigate, but the real fix lives in `player_character.gd`.
3. **Assets:** Replace the primitive box/CSG placeholders (weapons AND the arena blockout) with real 3D `.glb` / `.gltf` assets. (Art = Gemini's lane; keep the generator as the tuning rig.)
4. ~~**UI:** Add a dedicated crosshair and on-screen cooldown/ammo timers for abilities.~~ **DONE (Aug 25 2026)** -> HUD expanded in `player_character.gd`.
5. **Vehicles:** Hotwire + launch the parked cars - the arena already tags them (`vehicles`/`hotwireable` groups + meta) to wire into the Rocket Mower vehicle code.
6. **Interiors/Traps:** Furniture cover + a Home Alone-style trap/deployable system; swap the placeholder walkable ramps for real step-geometry stairs once the controller supports stair-stepping; add gable-end infill.
7. **Bots/Nav:** Bake a NavigationRegion over the arena (yards, streets, interiors) for AI pathing.

---
*End of Document. Next Agent: Please append your changes to "Recent Changes" when finishing your session.*
