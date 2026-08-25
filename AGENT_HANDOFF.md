# Roofers vs Landscapers - Game Design & Handoff Document

This document serves as the master tracking file for all currently implemented mechanics, classes, weapons, and synergies in the project. 

## 1. Core Systems

*   **Multiplayer Architecture:** The game runs on a `WebSocketMultiplayerPeer` backend, allowing for browser-compatible HTML5 web exports. It includes a programmatic Host/Join lobby UI.
*   **Aiming System:** Utilizes a "Warframe-style" True Crosshair TPS system. The camera is offset over the shoulder (swappable with `C`), and projectiles are dynamically calculated to fire from the weapon barrel towards the 3D position the center-screen crosshair is resting on.
*   **Archetype Weight System:** 
    *   **Light Classes:** Double Jump (`max_jumps = 2`), Fast base speed (`6.5`), Extreme Sprint (`1.8x`).
    *   **Medium Classes:** Single Jump (`1`), Standard speed (`6.0`), Standard Sprint (`1.4x`).
    *   **Heavy Classes:** Single Jump (`1`), Sluggish speed (`5.0`), Slow Sprint (`1.3x`).

## 2. Parkour & Traversal Mechanics

*   **Ledge Vaulting:** Approaching a ledge while falling and holding Jump (Spacebar) will freeze the player's fall and smoothly tween them up and over the ledge.
*   **Roof Sliding:** Walking on an angled surface (like a roof) and holding Crouch (Ctrl) disables friction and rapidly accelerates the player down the slope.
*   **Zipline Spool (Gadget):** A deployable traversal tool. Click once to place the start peg on a wall, click again to place the end peg. Spawns a physical cable that players can interact with (E) to attach to and slide along by holding Forward (W).

## 3. Weapons & Synergies

### Roofer Arsenal

*   **Pneumatic Nail Gun (Ranged):**
    *   *Primary:* Fires fast, physical nails that stick into enemies (applies a 5-second `stuck_nail` stack).
    *   *Alt-Fire (Steady Aim):* Zooms the camera in, reduces movement speed to 65%, and vastly tightens the bullet spread for accurate mid-range shots.
*   **The Pry Bar (Melee):**
    *   *Primary:* Standard melee swings.
    *   *Alt-Fire (Nail Puller & Deconstructor):* A precise strike that consumes all `stuck_nail` stacks on an enemy, violently ripping them out for 15 bonus burst damage per nail. If used on a gadget/deployable, it deals 300% damage to instantly shatter it.
*   **Gutter Sniper (Ranged):**
    *   *Primary:* High damage, single-shot. Strict 5-ammo limit to prevent infinite camping.
    *   *Alt-Fire (Scope):* Pushes the camera into a deep 1st-person FOV zoom. Restricts player movement to 40% and disables sprinting while held. Includes a menu setting to swap between Hold-to-ADS and Toggle-ADS.
*   **Shingle Slinger (Ranged):**
    *   *Primary:* Rapidly throws single, sharp roofing shingles.
    *   *Alt-Fire (Fan of Shingles):* Consumes 3 ammo to throw 5 shingles simultaneously in a wide horizontal shotgun spread.
*   **Hot Tar Gun (Ranged):**
    *   *Primary:* Fires heavy, arcing blobs of hot tar. Enemies hit are `tarred` for 4 seconds, suffering a 60% movement slow.
    *   *Alt-Fire (Ignite Flare):* Fires a fast-moving, glowing flare. If it strikes a `tarred` enemy, it consumes the tar to **Ignite** them, dealing 16 DPS for 3 seconds.

### Landscaper Arsenal

*   **Slingshot (Ranged):**
    *   *Primary:* Fires standard stones.
    *   *Alt-Fire (Special Ammo):* Loads special munitions (Rotten Fruit / Beehives) for varied status effects.
*   **Leaf Blower (Ranged):**
    *   *Primary:* Continuous stream.
    *   *Alt-Fire (Air Blast):* Consumes a chunk of ammo to fire a heavy physics burst that knocks enemies backward.
*   **Weed Wacker (Melee):**
    *   *Primary:* Continuous, rapid-ticking short-range hits.
    *   *Alt-Fire (Over-rev Dash):* Consumes 5 Gas to launch the player in a 25m/s horizontal dash, ending in a massive 40-damage AoE strike.
*   **Felling Axe (Melee):**
    *   *Primary:* Slow, heavy chops.
    *   *Alt-Fire (TIMBER!):* A 2.5s cooldown overhead slam. Deals 150% damage to players, and 999 damage to enemy gadgets/fortifications to instantly shatter them.

## 4. Vehicles
*   **Big Tony's Rocket Mower:** A driveable zero-turn mower. It protects the driver, taking damage in their place. When its HP reaches 0, it ejects the driver and explodes, dealing 25% max HP blast damage in an AoE.
