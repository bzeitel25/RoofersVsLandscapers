# 🏠 ROOFERS vs LANDSCAPERS
## Game Design Document (GDD) v1.0
### *"The Shingle That Started It All"*

---

**Working Title:** Roofers vs Landscapers  
**Genre:** Asymmetric Team PvP Brawler / King of the Hill  
**Platform:** PC (primary), Console (planned)  
**Engine:** Godot 4 (GDScript + C# where needed for performance)  
**Target Audience:** Teens & Young Adults (ESRB T — stylized cartoon violence)  
**Art Style:** Stylized 3D — cel-shaded / toon-shaded with exaggerated proportions. Silly, expressive characters. AI-assisted 3D pipeline (see Art Direction Addendum).  
**Players:** 4v4 (core), scalable to 6v6 or 8v8  
**Perspective:** Third-person (over-the-shoulder or slightly pulled back for spatial awareness)

---

## 1. High Concept

**Roofers vs Landscapers** is an asymmetric, round-based PvP brawler where two teams of blue-collar warriors wage all-out war over suburban rooftops. **Roofers defend the high ground.** **Landscapers storm it from below.** Armed with improvised weapons ripped straight from the job site — nail guns, leaf blowers, riding mowers, and worse — players clash in chaotic, physics-driven combat across increasingly absurd neighborhood arenas.

Think *Fortnite meets Team Fortress 2 meets Jackass*, with a king-of-the-hill structure and the comedic energy of a workplace dispute that went way, way too far.

---

## 2. The Lore — How It All Began

> It was supposed to be a quiet Tuesday in Crestwood Cul-de-sac.
>
> The Apex Roofing crew was patching shingles on 47 Maple Drive while GreenThumb Landscaping was mowing the lawn next door. Everything was fine — until it wasn't.
>
> A single asphalt shingle slipped off the roof. It tumbled, caught the wind, and landed — with surgical precision — directly into the intake of Big Tony Moretti's pride and joy: a custom-painted Deere ZTrak 900 riding mower with chrome spinners and a subwoofer.
>
> The mower choked. The blade jammed. The engine seized, coughed, and **exploded** — launching Big Tony twelve feet through Mrs. Henderson's prize-winning rose garden and into her birdbath.
>
> Tony's crew blamed the roofers. The roofers said it was the wind. Words were exchanged. Then thermoses. Then nail guns.
>
> By sundown, the entire block was a warzone. Ladders became siege towers. Leaf blowers became crowd-control weapons. Someone strapped a propane tank to a wheelbarrow.
>
> The HOA called an emergency meeting. The police gave up. The neighborhood watch started selling tickets.
>
> **The feud was on.**
>
> Now it's not about shingles or lawns anymore. It's about **pride**. It's about **territory**. It's about proving, once and for all, who the *real* kings of the cul-de-sac are.
>
> *The roof is the throne. Defend it — or take it.*

---

## 3. Core Gameplay Loop

```
┌─────────────────────────────────────────────────────┐
│                    ROUND START                       │
│                                                     │
│   ROOFERS: Deploy on rooftop, set up defenses       │
│   LANDSCAPERS: Spawn at ground level, plan assault  │
│                                                     │
├──────────────┬──────────────────────────────────────┤
│  SETUP PHASE │  60-90 seconds                       │
│  (Roofers)   │  Roofers MUST place 2-3 Extension    │
│              │  Ladders (baseline entry points).    │
│              │  Booby-trap the yard Home Alone style│
│              │  and fortify the roof.               │
├──────────────┼──────────────────────────────────────┤
│  ASSAULT     │  10-15 minutes per round             │
│  PHASE       │  Landscapers storm the roof          │
│              │  Roofers defend and manage resources │
│              │  Combat, chaos, improvised weapons   │
├──────────────┼──────────────────────────────────────┤
│  ROUND END   │  Win condition met OR time expires    │
│              │  Teams swap roles                     │
│              │  Best-of-3 or Best-of-5 series        │
└──────────────┴──────────────────────────────────────┘
```

### 3.1 The Asymmetry

This is the heart of the game. The two teams play fundamentally differently:

| Aspect | 🔨 Roofers (Defenders) | 🌿 Landscapers (Attackers) |
|--------|----------------------|---------------------------|
| **Spawn** | On the roof | Ground level |
| **Goal** | Survive / hold the roof | Reach the roof and eliminate all Roofers |
| **Strength** | High ground advantage, fortifications, traps | Mobility tools, numbers pressure, creative approach routes |
| **Weakness** | Limited escape routes, finite resources | Exposed during climb, less cover |
| **Playstyle** | Strategic, positional, defensive | Aggressive, creative, coordinated |

---

## 4. Win Conditions & Game Modes

### 4.1 Core Mode — *"King of the Roof"*
- **Time Limit:** Rounds last 10-15 minutes.
- **Landscapers win** if they knock out the entire Roofer team and hold the roof uncontested for 10 seconds. (Subject to playtesting tweaks).
- **Roofers win** if they survive until time expires and win the Sudden Death Overtime.
- **Respawns (Scaling):** Both teams have unlimited lives during regulation. However, respawn timers increase the longer the game goes on, making late-game mistakes highly punishing.
- **Sudden Death Overtime:** When the clock hits 0:00, respawns are permanently disabled. The game continues until only one team remains standing. This creates a high-stakes grand finale.
- Teams swap sides after each round. Best of 3.

### 4.2 *"Ticket Brawl"* (TDM Variant)
- Each team has a shared pool of respawn tickets (e.g., 20).
- When a player is KO'd, their team loses a ticket.
- Landscapers still need to reach the roof, but KOs matter more.
- First team to drain the other's tickets wins the round.

### 4.3 *"Overtime Madness"*
- If the Landscapers have at least one player on the roof when the timer expires, the game enters **Overtime** — the clock resets to 60 seconds and the roof starts **shrinking** (sections collapse/crumble), forcing both teams into a tighter arena until one side is wiped.

### 4.4 *"Grudge Match"* (1v1 / 2v2)
- Smaller rooftop maps. One attacker, one defender.
- Fast rounds. First to 5 KOs.
- Great for ranked/competitive play.

### 4.5 *"Neighborhood Blitz"* (Large Scale — Future Mode)
- 8v8 across a multi-house neighborhood.
- Landscapers must capture rooftops in sequence (like Battlefield's Rush mode).
- Roofers fall back to the next house as each rooftop falls.

---

## 5. Characters & Classes

Each team has a roster of playable characters (classes) with unique abilities, stats, and personalities. Characters are unlockable and customizable.

### 5.1 🔨 Roofer Classes

| Class | Nickname | Role | Signature Melee | Signature Ranged | Signature Utility/Ability |
|-------|----------|------|-----------------|------------------|---------------------------|
| **The Foreman** | "Boss Man" | Tank / Heavy | Framing Hammer | Caulk Cannon | **Rally Cry** — Buffs nearby allies' defense for 8 sec |
| **The Nailer** | "Tack" | DPS / Light | Pry Bar | Pneumatic Nail Gun (Burst-fire, high recoil) | **Zipline Spool** — Deploys a line for fast traversal. |
| **The Tar King** | "Sticky" | Area Denial | Tar Mop | Hot Tar Bucket (thrown) | **Tar Pit** — Creates a large sticky zone that slows enemies and deals DoT |
| **The Shingle Slinger** | "Frisbee" | Ranged | Roofing Hatchet | Shingle Discs | **Shingle Storm** — Throws a fan of shingles in an arc |
| **The Gutter Sniper** | "Downspout" | Sniper | Caulking Knife | Modified Caulk Gun (Sniper) | **Gutter Slide** — Can slide along roof gutters at high speed for repositioning |
| **The Cleanup Guy** | "The Spy" | Infiltrator | Scraper | Nail Pouch | **Undercover** — Disguises as a Landscaper to sneak to ground level. |
| **The Apprentice** | "Rookie" | Support | Screwdriver | Staple Gun | **Patch Job** — Repairs ally health and fortifications |
| **The Mag-Sweep** | "Scrap" | Defender | Rolling Magnet | Magnetic Shotgun | **Magnetic Catch** — Parries/catches metallic projectiles in mid-air and fires them back. |
| **The Electrician** | "Sparky" | Trapper / DPS | Jumper Cables | Wire-Spool Taser | **Live Wire** — Electrifies puddles (water/tar) to create massive shock zones. |
| **The HVAC Tech** | "Freon" | Heavy / Control | Pipe Wrench | Refrigerant Tank (Freezes) | **The AC Drop** — Manifests a massive AC unit in mid-air that drops like a piano, shattering frozen enemies. |

### 5.2 🌿 Landscaper Classes

| Class | Nickname | Role | Signature Melee | Signature Ranged | Signature Utility/Ability |
|-------|----------|------|-----------------|------------------|---------------------------|
| **The Gardener** | "Sprout" | DPS / Light | Pocket Knife | Hunting Slingshot (Fast reload) | **Pest Control** — Throws projectiles (fruit, beehives) much farther than other classes. |
| **The Lumberjack** | "Chop" | Heavy / Siege | Felling Axe | Crossbow (Shoots wood) | **Timber!** — Fells trees for wood resources, destroying cover to build siege gear. |
| **The Botanist** | "Flora" | Support | Pruning Shears | Seed Spreader | **Harvest** — Brews potions and grows refreshing fruit to heal teammates. |
| **The Mower** | "Big Tony" | Tank (Mech) | Detached Blade | Potato Gun | **Mech/Pilot Form** — Starts in his Rocket Mower (Mech). When destroyed, his body cast shatters and he fights on foot. |
| **The Trimmer** | "Hedge" | Flanker | Hedge Trimmer | Weed Whacker | **Trimmer Tornado** — Spin attack that shreds through barricades |
| **The Blower** | "Gust" | Crowd Control | Rake | Leaf Blower | **Hurricane Force** — Supercharged gust that can blow enemies off the roof |
| **The Raker** | "Scratch" | Trapper | Rake | Fertilizer Bomb | **Rake Field** — Deploys hidden rakes; enemies take damage and get stunned |
| **The Sprinkler** | "Splash" | Area Control | Trowel | Garden Hose | **Sprinkler System** — Deploys sprinklers that create slippery zones on the roof |
| **The Climber** | "Spider" | Scout | Climbing Pick | Grappling Hook | **Canopy Launch** — Can launch from trees to reach elevated positions quickly |
| **The Hobbyist** | "Buzz" | Air Support | Screwdriver | Drone Controller | **Quadcopter** — Pilots a drone to scout roof defenses and drop payloads. |

---

## 6. Weapons & Equipment

### 6.1 Weapon & Gadget System
All weapons are improvised from job-site tools. Nothing is purpose-built for combat. 
- **The Loadout (The Rule of 3):** Every class spawns with a **Signature Melee Weapon**, a **Signature Ranged Weapon**, and a **Signature Gadget/Utility Item**. 
- **Universal Usability:** Abilities are tied to the *tool*, not the class or team. If a Roofer picks up a dropped Rake, they can build a Leaf Pile. If a Landscaper picks up a dropped Nail Gun, they can use it. **Don't leave your gear where the enemy can grab it.**
- **Pickups & Swapping:** Secondary weapons and gadgets spawn around the map. Picking up a new one replaces your current Ranged or Gadget item and drops it on the ground for anyone (friend or foe) to grab. You can never drop your Melee weapon.
- **Death & Respawn:** When you die, you drop your swapped weapons and respawn with your default 3-piece class signature loadout.
- **Damage vs. Healing:** Time-to-Kill (TTK) mirrors *Team Fortress 2* / *Overwatch*. Healing mechanics exist, but **Damage always outpaces Healing**. Turtling and out-healing damage is impossible.

### 6.2 Weapon Categories

#### Melee
| Weapon | Type | Notes |
|--------|------|-------|
| Framing Hammer | Blunt | Slow, heavy hits. Can nail enemies to surfaces briefly. |
| Crowbar | Blunt | Fast swings, good for prying open barricades. |
| Rake | Reach | Long range melee. Step-on trap variant. |
| Hedge Trimmer | Blade | Rapid damage, short range. Shreds barricades. |
| Shovel | Blunt | Can dig (create small cover holes) and smack. |
| Pruning Shears | Blade | Fast, precise, bonus damage from behind. |
| 2x4 Lumber | Blunt | Breakable but devastating. Can be thrown. |

#### Ranged
| Weapon | Type | Notes |
|--------|------|-------|
| Nail Gun | Projectile | Rapid semi-auto. Nails can pin to surfaces. |
| Caulk Gun (Modified) | Projectile | Slow, high-damage globs. Slows on hit. |
| Shingle Discs | Thrown | Arcing projectiles, ricochet off surfaces. |
| Staple Gun | Projectile | Fast ROF, low damage, good for suppression. |
| Seed Spreader | Spread | Shotgun-like burst of seeds/gravel. |
| Potato Gun | Launcher | Improvised cannon. Arcing shots. High damage. |
| Garden Hose | Stream | Continuous stream. Pushes enemies, makes surfaces slippery. |
| **Flamethrower** | Stream | **Rare Map Spawn.** High damage, destroys wooden structures and leaf piles instantly. |
| **Beehive/Wasp Nest** | Thrown / Siege | Thrown by hand or launched via Trebuchet. Creates an angry AoE swarm that causes DoT and panic (players move erratically). |

#### Utility / Gadgets (Side-Items)
These occupy the **Gadget Slot**. They operate on cooldowns rather than ammo, and can be swapped out at spawn points or dropped by dead players.

| Gadget | Description | Cooldown |
|--------|-------------|----------|
| **Tarp Glider** | Hold jump in mid-air to deploy. Safely descend or cross gaps. | 5-10s |
| **Gravity Work Boots** | Grants a super-jump and completely negates fall damage. | 5s |
| **Grappling Hook** | Pulls you to a surface, or pulls an enemy to you. | 7s |
| **Zipline Spool** | Shoot two points to create a permanent zipline anyone can ride. | 15s |
| **Leaf Blower** | Pushback beam. Can redirect projectiles. | 8s |
| **Tar Bucket** | Throwable AoE slow + DoT. | 10s |
| **Rope Lasso** | Pull enemies off ledges or pull yourself up. | 7s |
| **Wheelbarrow Shield**| Mobile cover. Can be loaded with stuff and pushed at enemies. | N/A |
| **Bag of Fertilizer** | Throwable smoke/stink bomb. Obscures vision. | 12s |

### 6.3 Vehicles, Siege Engines & Heavy Traversal Gear (Map Spawns / Player Built)

| Item | Team | Description |
|------|------|-------------|
| **Rocket Mower** | Landscaper | Can be driven up ramps to launch onto roofs. Can crash through Roofer fences and barricades at high speed. |
| **Construction Umbrella / Tarp** | Landscaper | Player-built. Heavy-duty deployable canopy that blocks plunging sniper fire. Essential for protecting Builders/Lumberjacks while they work. |
| **Siege Ramps** | Landscaper | Player-built wooden ramps. Combine with the Rocket Mower to dictate exactly where the mower breaches the roof. |
| **Static Trebuchet** | Landscaper | Player-built. Massive range and damage. Launches logs, coconuts, or fertilizer stink-bombs. |
| **Mobile Siege Mower** | Landscaper | Player-built. Jerry-rig a small catapult onto a push-mower or riding mower. Allows a player to wheel artillery out of the woods and fire on the move. |
| **The Woodchipper** | Landscaper | Map Spawn. Feed it wood or debris to spray a continuous, high-speed cone of mulch at the roof. Acts as a flak cannon (hard counters drones) and obscures Roofer vision. |
| **Wheelbarrow Catapult** | Landscaper | One sits in the bucket, another launches them. Imprecise but hilarious. |
| **Extension Ladder** | Map Spawn | Deployable ladder. Roofers can push it down. |
| **Leaf Piles** | Built | Built by **anyone** holding a Rake who channels for 3 seconds. Soft landing (negates fall damage) or stealth zone (hide inside). Countered by Blowers or Fire. |
| **Trampoline** | Map Spawn | Deployable bounce pad. Roofers can destroy it. |
| **Tree Slingshot** | Landscaper | Bend a tree back, launch yourself. High arc, imprecise. |
| **Scaffold Tower** | Roofer | Deployable elevated platform for sniping/overwatch. |
| **Roof Hatch** | Roofer | Can seal/open hatches to control interior access routes. |

### 6.4 Roofer Defenses & Environmental Warfare
Roofers are masters of the high ground, but they can also turn the entire property into a *Home Alone*-style deathtrap.

**The Power Grid (Risk/Reward):**
*   **The Default Outlet:** The roof has one safe, built-in power outlet. It can power the Roofer Minimap/Radar *or* one basic turret.
*   **The Extension Cords:** To power multiple heavy defenses (like Spinning Saw-Blade Sentries or Advanced Radar), Roofers must drop bright orange extension cords down the side of the house to plug into the ground-level exterior outlets. 
*   **The Sabotage:** Landscapers can simply unplug these cords from the wall, OR cut them with bladed melee weapons (Machetes, Axes, Shears). Cutting the cord instantly disables the connected traps and kills the Roofer Minimap/Radar until an Apprentice/Support class repairs it by hand.

**Gutter Warfare:**
*   Gutters aren't just decorative; they are fluid transport systems. Roofers can pour resources directly into the gutters at the roofline.
*   **Payloads:** Pour in water to flood the yard and create slippery mud zones. Pour in Hot Tar to slow attackers. Dump a bucket of Nail Caltrops down the drain.
*   Gravity shoots the payload out of the ground-level downspouts like a shotgun blast, perfectly ambushing Landscapers who are hugging the house walls.

**Skylight Traps & "The Cartoon Fight Cloud":**
*   Roofers can loosen shingles or place fake tarps over skylights.
*   If a Landscaper falls through a trap into the house's interior, they don't just spawn outside. Instead, they trigger a classic **Cartoon Fight Cloud** inside the living room.
*   The camera shakes, and players see a massive dust cloud with stars, sparks, and comic-book sounds (angry family yelling, dog barking, cats screeching).
*   The Landscaper takes damage and is violently ejected out the front door back onto the lawn a few seconds later.

---

## 7. Map Design Philosophy

### 7.1 Core Principles
- Every map is a **suburban house and its surrounding yard/property**.
- Rooftops are the primary combat zone — multi-level, with ridges, dormers, chimneys, and skylights creating varied terrain.
- The ground level and vertical space between ground and roof is the **approach zone** — full of cover, climbable objects, and environmental hazards.
- **The Perimeter Zone:** The outer edges of the map (dense woods, neighbor's fences) serve as deep cover. Landscapers can use these blind spots to secretly construct siege weapons out of the Roofers' line of sight, then wheel them out when ready.
- **Dynamic Cover vs. Resources:** Trees and large bushes provide vital natural cover. However, the Lumberjack can cut these down to harvest Wood. This creates a constant tactical tension: keep the tree for protection, or destroy it to build a trebuchet?
- Maps should support **multiple approach routes** so Landscapers aren't funneled.
- **Destructible elements** — fences, barricades, parts of the roof, lawn furniture.

### 7.2 Map List (Launch)

#### 🏡 Crestwood Cul-de-sac — *"Ground Zero"*
> *Where it all began. The shingle. The mower. The birdbath.*
- Medium-sized two-story colonial home.
- Classic suburban yard with fence, shed, big oak tree, driveway.
- Balanced map. Good for learning. Multiple ladder points, one good ramp angle.
- **Hazard:** Mrs. Henderson's automated sprinkler system activates randomly, creating slippery zones.

#### 🏚️ The McMansion — *"Fortress of Excess"*
> *Three-car garage. Five bedrooms. Zero taste. One massive roof.*
- Large, complex rooftop with multiple levels, a widow's walk, and a rooftop pool (drained).
- Huge yard with gazebo, hedge maze, and a detached pool house.
- Favors defenders slightly — lots of angles to cover.
- **Hazard:** The HOA drone circles the map and occasionally dive-bombs players on both teams.

#### 🏗️ The Construction Site — *"Half-Built"*
> *They never finished this house. Now it's an arena.*
- Partially constructed house. Exposed framing, missing walls, unfinished roof sections.
- Vertical gameplay — scaffolding, exposed floor joists, hanging drywall.
- Very open, lots of sightlines but also lots of cover gaps.
- **Hazard:** Unstable floor sections can collapse underfoot.

#### 🏠 The Ranch House — *"Low Rider"*
> *Single story. Low roof. Absolute chaos.*
- Very low rooftop — Landscapers can almost jump up.
- Extremely fast-paced. Constant engagement.
- Tiny yard, close quarters. Lawnmower ramp right up the driveway.
- **Hazard:** The homeowner's aggressive Roomba patrols inside and occasionally bursts out of doors.

#### 🏰 The Victorian — *"The Tower"*
> *Three stories. Turrets. A widow's walk. Good luck.*
- Tall, complex roof with steep pitches and decorative spires.
- Very hard for Landscapers to reach the top. Rewards creative approaches.
- Surrounding yard has tall trees (slingshot opportunities) and a greenhouse (breakable cover).
- **Hazard:** Loose shingles slide down steep roof sections like avalanches.

#### 🏫 The Barn Conversion — *"Old MacDonald's Last Stand"*
> *Used to be a barn. Still smells like one.*
- Large, open interior (hay loft = second level).
- Gambrel roof — steep sides, flat top.
- Rural setting: tractor, hay bales, silo (alternate high ground).
- **Hazard:** Hay bale avalanche can be triggered by destroying support beams.

---

## 8. Traversal & Movement

### 8.1 Landscaper Traversal (Attacking)

Getting on the roof is the core challenge. Landscapers have multiple options, each with tradeoffs:

| Method | Speed | Noise | Risk | Skill Ceiling |
|--------|-------|-------|------|---------------|
| Extension Ladder | Slow | Medium | Medium — can be pushed down | Low |
| Grappling Hook | Fast | Low | High — vulnerable mid-zip | Medium |
| Rocket Mower Ramp | Very Fast | **VERY LOUD** | Very High — wild trajectory | High |
| Wheelbarrow Catapult | Fast | Medium | High — imprecise landing | High |
| Trampoline | Medium | Medium | Medium — predictable arc | Low |
| Tree Slingshot | Fast | Low | High — imprecise, can overshoot | High |
| Interior Stairs (if accessible) | Slow | Low | Low — but Roofers can trap | Low |
| Human Pyramid (team boost) | Slow | Low | Medium — multiple players exposed | Medium |

### 8.2 Roofer Mobility (Defending) & Fall Damage
- **Fall Damage is ACTIVE:** Dropping or getting pushed off the roof to the grass deals significant fall damage.
- **Mitigation:** Roofers must use their Gadgets (Tarp Gliders, Gravity Work Boots, Ziplines) to safely descend if they want to chase a weakened Landscaper or restock at the Work Van. Without these tools, giving up the high ground hurts.
- **Roof Running:** Navigate ridges, slide down slopes, leap between dormers.
- **Gutter Grinding:** Slide along gutters for fast lateral repositioning.
- **Chimney Vault:** Use chimneys as cover and vaulting points.

---

## 9. Economy & Progression

### 9.1 In-Match Economy & Supply Runs
- **Scrap (Roofers):** Currency spent on traps, barricades, and gadgets.
- **The Work Van (Roofer Restock):** Roofers start with limited scrap. To restock, they must drop down to ground level and loot their **Work Van**. This creates a high-risk, high-reward dynamic where Roofers give up the high ground to go on supply runs.
- **Wood & Raw Materials (Landscapers):** Earned by hacking down trees, dismantling fences, and destroying Roofer defenses. Used by builders (like the Lumberjack) to construct Defensive Tarps, Siege Ramps, and Trebuchets. 
- **Overtime Bonus:** Extra resources awarded if the match goes to Overtime.

### 9.2 Meta Progression
- **XP & Levels:** Earn XP from matches. Level up to unlock new characters, weapons, and cosmetics.
- **Battle Pass (Seasonal):** "The Job Site" — themed cosmetic tiers each season.
- **Crew Reputation:** Team-based reputation system. Play with friends, build your crew, earn crew-exclusive rewards.

### 9.3 Monetization Philosophy
- **Cosmetics ONLY.** No pay-to-win. No gameplay-affecting purchases.
- Skins, emotes, weapon wraps, victory animations, voice lines.
- Seasonal Battle Pass with free and premium tracks.

---

## 10. Cosmetics & Customization

### 10.1 Character Skins (Examples)

| Character | Skin Name | Description |
|-----------|-----------|-------------|
| Big Tony (The Mower) | "NASCAR Tony" | Racing suit, helmet, flames on the mower |
| Big Tony | "Zen Tony" | Yoga outfit, riding a meditation-themed mower, eerily calm |
| The Nailer | "Steampunk Tack" | Brass and copper nail gun, goggles, Victorian work clothes |
| The Blower | "DJ Gust" | Turntable leaf blower, headphones, drops bass with every gust |
| The Foreman | "Hard Hat Hero" | Golden hard hat, cape made of caution tape |
| The Raker | "Grim Raker" | Grim Reaper outfit, rake replaces scythe |
| The Tar King | "Fondue Sticky" | Chef outfit, tar bucket replaced with fondue pot |

### 10.2 Emotes & Taunts
- **"The Shingle Drop"** — Holds up a shingle, drops it, shrugs.
- **"Mow & Bow"** — Revs a tiny mower, takes a bow.
- **"Nailed It"** — Finger guns with nail gun sound effects.
- **"Leaf Me Alone"** — Aggressively leaf-blows at the camera.
- **"Roof Dance"** — Victory dance on the roof peak.
- **"Union Break"** — Sits down, pulls out a thermos and sandwich.

### 10.3 Victory Screens
- **Roofer Victory:** Team poses on the intact roof. "ROOF SECURED" banner. Confetti made of shingles.
- **Landscaper Victory:** Team poses on the conquered roof, planting a flag (garden stake with a "GreenThumb" pennant). The roof is cracked and battered. A lawn gnome is planted on the chimney.

---

## 11. Audio & Music

### 11.1 Music Direction
- **Menu Theme:** Upbeat punk-rock/ska with construction sounds mixed in (hammering as percussion, saw as guitar riff, mower engine as bass).
- **Gameplay Music:** Dynamic — escalates with combat intensity. Starts chill (acoustic country/folk), gets heavier as the fight intensifies (punk/metal).
- **Overtime Music:** Full-on adrenaline — fast drums, distorted guitars, air horn stabs.

### 11.2 Sound Design
- Every weapon should have **chunky, satisfying audio feedback**.
- Environmental sounds: birds chirping, dogs barking, distant lawnmowers, suburban ambience.
- **Announcer:** An overly dramatic HOA president who commentates the match.
  - *"The Landscapers have BREACHED the roof! Somebody call the contractor!"*
  - *"That's a CODE VIOLATION if I've ever seen one!"*
  - *"OVERTIME! Property values are PLUMMETING!"*

---

## 12. UI & HUD

### 12.1 In-Game HUD
- **Health Bar:** Styled as a work order clipboard (health = completion percentage, reversed).
- **Ammo / Fuel:** Displayed as tool battery charge or gas gauge.
- **Team Status:** Small portraits of teammates with health indicators.
- **Minimap:** Overhead view of the property. Roof zones highlighted. Active traversal points marked.
- **Timer:** Large, central. Styled as a punch clock.
- **Kill Feed:** Styled as a radio dispatch. *"Tack nailed Gust with the Pneumatic Nail Gun."*

### 12.2 Menus
- **Main Menu:** A suburban cul-de-sac at golden hour. Camera pans slowly. Characters idle in the background (sharpening tools, revving mowers, stretching).
- **Matchmaking:** A bulletin board at the hardware store. Game modes are pinned notes.
- **Loadout Screen:** A tool bench (Roofers) or a garden shed (Landscapers). Weapons are laid out on the surface.

---

## 13. Technical Specifications (Target)

| Spec | Target |
|------|--------|
| **Engine** | Godot 4 (GDScript + C# where needed for performance) |
| **Rendering** | Godot's Vulkan Forward+ renderer with cel/toon shaders (godot4-cel-shader or custom) |
| **Tick Rate** | 60 Hz (server) |
| **Netcode** | NetFox addon (authoritative multiplayer with client prediction, reconciliation, lag comp) |
| **Physics** | Godot Physics (Jolt backend) for ragdolls, projectiles, mower launches, debris |
| **Destruction** | Partial destruction system (barricades, roof sections, fences, props) via mesh swapping + particles |
| **3D Asset Pipeline** | Gemini Pro (concept art) → TRELLIS/TripoSR/Hunyuan3D (free, HuggingFace) → Blender (free) → AccuRIG (free) → Mixamo (free) → Godot |
| **AI Tools** | Gemini Pro (image gen), Claude Pro (code/prompts/analysis), free HuggingFace 3D generators |
| **Import Formats** | glTF 2.0 (primary), .blend (direct import), OBJ (fallback) |
| **Environment Tools** | Terrain3D + ProtonScatter (free Godot addons) |
| **Min PC Spec** | GTX 1060 / Ryzen 5 2600 / 8GB RAM |
| **Target FPS** | 60 FPS (low settings) / 120+ FPS (high-end) |
| **Max Players** | 16 (8v8 in Neighborhood Blitz) |
| **Total Tool Cost** | \$0 beyond existing Gemini Pro + Claude Pro subscriptions |

---

## 14. Development Roadmap

### Phase 1 — Vertical Slice (Months 1–4)
- [ ] Core movement and combat prototype in Godot 4
- [ ] 2 Roofer classes, 2 Landscaper classes
- [ ] 1 map (Crestwood Cul-de-sac)
- [ ] King of the Roof mode (basic)
- [ ] Basic traversal: ladders, grappling hook, rocket mower ramp
- [ ] Art style established — toon shader pipeline in Godot
- [ ] AI asset pipeline validated (model → cleanup → Godot)

### Phase 2 — Alpha (Months 5–8)
- [ ] All 6+6 launch classes
- [ ] 3 maps
- [ ] All core weapons and gadgets
- [ ] Full traversal system
- [ ] Setup Phase for Roofers (traps, barricades)
- [ ] UI/HUD v1
- [ ] Basic matchmaking (Godot multiplayer + lobby system)
- [ ] First full art pass across all characters and maps

### Phase 3 — Beta (Months 9–12)
- [ ] All 6 launch maps
- [ ] Ticket Brawl and Overtime Madness modes
- [ ] Progression system (XP, unlocks)
- [ ] Cosmetics system
- [ ] Audio pass (music, SFX, announcer VO)
- [ ] Closed beta testing
- [ ] Anti-cheat integration
- [ ] Performance optimization & shader tuning

### Phase 4 — Launch (Months 13–15)
- [ ] Open beta
- [ ] Final polish, balancing
- [ ] Season 1 Battle Pass
- [ ] Marketing push
- [ ] **LAUNCH**

### Post-Launch
- New characters every season
- New maps quarterly
- Neighborhood Blitz mode
- Grudge Match (ranked)
- Seasonal events (Halloween — Haunted House map, Summer — Water Park map)
- Community workshop / custom maps (long-term goal)

---

## 15. Competitive & Social Features

### 15.1 Ranked Play
- Seasonal ranked ladder.
- Rank tiers themed as job promotions: **Apprentice → Journeyman → Contractor → Foreman → Master Builder** (Roofer) / **Intern → Crew Lead → Supervisor → Landscape Architect → Grounds Emperor** (Landscaper).
- Placement matches → MMR-based matchmaking.

### 15.2 Social
- **Crews:** Persistent friend groups (4–8 players). Crew leaderboards, crew banners, crew emotes.
- **Replay System:** Full replay with free camera. Clip editor for sharing highlights.
- **Spectator Mode:** For esports/content creation.

---

## 16. Pillars of Design

> These are the non-negotiable principles that every design decision should be measured against:

### 🎯 Pillar 1: Asymmetry Is the Fun
The attacker/defender dynamic is the game's identity. Every system should reinforce the feeling that these two teams play *differently* — not just reskinned versions of each other.

### 🎯 Pillar 2: Creativity Over Meta
Players should feel rewarded for trying wild, improvised strategies. The rocket mower ramp should feel like a *good idea* even when it fails spectacularly. Emergent gameplay > optimal gameplay.

### 🎯 Pillar 3: Easy to Pick Up, Deep to Master
A new player should be able to grab a rake, climb a ladder, and have fun in their first match. But mastering grappling hook trajectories, mower launch angles, and coordinated team pushes should take hundreds of hours.

### 🎯 Pillar 4: Slapstick, Not Sadistic
Violence is exaggerated, cartoonish, and *funny*. Getting hit by a rake should make you laugh even when it happens to you. No blood, no gore — just ragdoll physics, comedic sound effects, and absurd weapon interactions.

### 🎯 Pillar 5: The Roof Matters
The rooftop should feel like a real, physical space with slopes, hazards, and tactical options — not just a flat platform. Controlling the roof should feel *earned*.

---

## 17. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Asymmetric balance is hard to tune | High | High | Extensive playtesting; role-swap every round ensures both sides feel fair |
| Traversal can feel frustrating for Landscapers | Medium | High | Multiple approach routes; fast respawns; traversal gear variety |
| Niche theme may limit audience | Medium | Medium | Lean into humor and absurdity; the theme is a hook, not a barrier |
| Godot 4 multiplayer maturity | Medium | High | Use proven ENet layer; supplement with custom netcode where needed; community addons |
| AI-generated 3D assets need cleanup | High | Medium | Budget time for Blender cleanup; establish quality bar early; use AI as starting point not final output |
| Content drought post-launch | Medium | High | Plan 4 seasons of content before launch; community map tools as long-term solution |

---

## 18. Inspirations & References

| Game | What We Take From It |
|------|---------------------|
| **Fortnite** | Art style tone, cosmetics model, accessibility |
| **Team Fortress 2** | Class-based design, personality-driven characters, humor |
| **Overwatch** | Asymmetric attack/defend structure, hero abilities |
| **Gang Beasts** | Slapstick physics, comedy of clumsy violence |
| **Siege (R6)** | Defender setup phase, attacker planning, destructible environments |
| **Deep Rock Galactic** | Blue-collar worker aesthetic, team camaraderie, "working class heroes" energy |
| **Knockout City** | Skill-based thrown weapons, team coordination, pick-up-and-play fun |

---

## Appendix A: Glossary

| Term | Definition |
|------|-----------|
| **KO** | Knockout — when a player's health reaches zero. They ragdoll dramatically. |
| **The Roof** | The primary objective zone. Sacred ground. |
| **Scrap** | In-match currency earned through gameplay. |
| **Setup Phase** | Pre-round phase where Roofers prepare defenses. |
| **Approach** | The act of Landscapers moving from ground level to the roof. |
| **The Shingle Incident** | The canonical event that started the war. Referenced everywhere. |

---

## Appendix B: Future Ideas (Parking Lot)

- **Environmental Storytelling:** Each map has hidden lore items telling the story of the neighborhood's descent into chaos.
- **NPC Hazards:** Angry homeowners, confused mail carriers, territorial dogs that attack both teams.
- **Weather System:** Rain makes roofs slippery. Wind affects projectiles. Snow creates new traversal options.
- **Cross-Trade Characters:** Electrician, plumber, and painter DLC characters that can play on either team as mercenaries.
- **Map Editor:** Let players build their own houses and yards.
- **Single-Player Campaign:** *"The Origin Story"* — Play through the Shingle Incident and the escalating feud. Tutorial + lore delivery.

---

*"The roof is the throne. Defend it — or take it."*

**— END OF GDD v1.0 —**
