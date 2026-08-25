# 🎨 ROOFERS vs LANDSCAPERS
## Art Direction & 3D Pipeline Addendum v2.0
### Zero-Budget, AI-Driven Character & Asset Production for Godot 4

---

> **Core Constraint:** Solo dev, zero income. Gemini Pro + Claude Pro are the primary AI workhorses. Every other tool must be **free or open-source**. No paid subscriptions, no paid plugins.

---

## 1. Art Style: Stylized Cel-Shaded 3D (TF2 Energy)

### 1.1 The Look

The primary inspiration is **Team Fortress 2** — characters that are:
- **Semi-proportional** — real human proportions but pushed ~15-20% toward caricature
- **Goofy, not absurd** — no bighead mode, no chibi. Think "slightly exaggerated action figures"
- **Instantly readable** — every class has a unique silhouette you can identify at a glance
- **Expressive** — big facial features (thick brows, wide mouths) that sell personality even from a distance

### 1.2 Proportion Guide

```
TF2 Style Reference:
┌──────────────────────┐
│  ~6.5 heads tall     │  ← Slightly shorter than realistic (7.5 heads)
│  Broad shoulders     │  ← Exaggerated by ~20% for readability  
│  Big hands           │  ← Need to read clearly when holding tools
│  Thick limbs         │  ← Chunky, sturdy silhouettes
│  Normal head size    │  ← NOT enlarged. Faces are expressive but proportional.
│  Slightly short legs │  ← Gives a planted, sturdy feel (these are working men)
└──────────────────────┘
```

**What this ISN'T:**
- ❌ Chibi / bobblehead / bighead mode
- ❌ Hyperrealistic
- ❌ Stick-figure / low-poly minimalist
- ❌ Anime (no giant eyes, no spiky hair)

**What this IS:**
- ✅ TF2's Heavy vs Scout proportional range
- ✅ Fortnite's character builds (athletic to beefy)
- ✅ Hi-Fi Rush character proportions
- ✅ "Pixar dad-bod" energy for the tanks, "lanky teenager" for scouts

### 1.3 Why Cel-Shading

| Reason | Details |
|--------|---------|
| **Hides AI mesh flaws** | Flat stepped lighting smooths over bumpy AI-generated surface contours |
| **Masks texture noise** | AI textures have inconsistent micro-detail; cel-shading uses flat color bands |
| **Forgives rigging issues** | Thick outlines draw the eye to silhouettes, not joint deformation |
| **Eliminates baked-lighting** | AI models bake ambient light into textures; toon shaders override this |
| **Matches TF2 tone** | Cartoonish, readable, ages well, perfect for slapstick comedy |
| **Cheap to render** | Toon shaders are lighter than PBR; helps with multiplayer performance |

---

## 2. The Zero-Budget Tool Stack

### 2.1 Complete Pipeline — Every Tool Free

| Step | Tool | Cost | Role |
|------|------|------|------|
| **Concept Art** | **Gemini Pro** (Imagen 3) | Included in sub | Character sheets, turnarounds, weapon concepts, environment mood boards |
| **Art Direction & Prompts** | **Claude Pro** | Included in sub | Writes detailed prompts for Gemini, analyzes/critiques art, writes all code |
| **3D Model Generation** | **TRELLIS 2** (HuggingFace Space) | **Free** | Image-to-3D mesh, no local GPU required |
| **3D Model Generation** | **TripoSR** (HuggingFace Space) | **Free** | Ultra-fast backup generator (<0.5s) |
| **3D Model Generation** | **Hunyuan3D 2.1** (HuggingFace Space) | **Free** | Best for PBR texture maps alongside mesh |
| **3D Model Generation** | **Stable Fast 3D** (HuggingFace Space) | **Free** | Built-in UV unwrapping, great for props |
| **AI Retopology** | **MeshAnything V2** (HuggingFace Space) | **Free** | Converts dense AI meshes to clean game-ready topology |
| **Mesh Cleanup & Retopo** | **Blender 4.x** + **RetopoFlow** (GitHub) | **Free** | Manual cleanup, retopology, UV unwrap |
| **UV Tools** | **TexTools for Blender** (GitHub) | **Free** | Rectify UVs, texel density, island packing |
| **AI Texturing** | **Dream Textures** (Blender addon, GitHub) | **Free** | Stable Diffusion inside Blender for seamless textures |
| **Texture Baking** | **TexTools** / **Principled Baker** (GitHub) | **Free** | Bake Normal, AO, Curvature, Roughness maps |
| **Auto-Rigging** | **Reallusion AccuRIG** | **Free** | 19-point body + 5-finger auto-rig |
| **Animation Library** | **Adobe Mixamo** | **Free** | 2,000+ mocap animations |
| **Custom Animation** | **Cascadeur** (free tier) | **Free** | AI physics-assisted keyframe animation |
| **Game Engine** | **Godot 4** | **Free** | Open source, forever free |
| **Cel Shader** | **godot4-cel-shader** (GitHub) | **Free** | Complete toon shader with outlines |
| **Multiplayer** | **NetFox** (GitHub) | **Free** | Server authoritative netcode with prediction |
| **💰 TOTAL** | | **\$0/month beyond existing subs** | |

### 2.2 Role Split: Gemini vs Claude

| Task | Gemini Pro | Claude Pro |
|------|-----------|-----------|
| **Generate concept art** | ✅ Primary — Imagen 3 outputs PNGs directly | ❌ No native image generation |
| **Character turnaround sheets** | ✅ Can generate front/side/back in one image | ❌ Can't generate raster images |
| **Iterate on designs** | ✅ Multi-turn inpainting ("change the hat to a hard hat") | ❌ Analyzes and critiques images only |
| **Style transfer** | ✅ Re-render images into cel-shaded style | ❌ |
| **Write Gemini prompts** | ❌ | ✅ Superior — crafts detailed, layered art prompts |
| **Write Godot code** | Good | ✅ **Best** — flawless GDScript, shaders, C# |
| **Write Blender scripts** | Good | ✅ **Best** — Python bpy scripts for batch processing |
| **Analyze 3D topology** | Basic | ✅ Can critique mesh screenshots, suggest fixes |
| **Generate SVG assets** | ❌ | ✅ UI icons, HUD elements, vector graphics |
| **Procedural mesh code** | Good | ✅ GDScript ArrayMesh/SurfaceTool generators |

**The workflow:** Claude writes the prompts → Gemini generates the images → Free tools make the 3D → Claude writes the code to integrate it all in Godot.

---

## 3. Step-by-Step Production Pipeline

### Step 1: Character Concept Art (Gemini Pro)

Use Claude to craft the prompt, then feed it to Gemini:

**Claude writes the prompt:**
> *"Write me a Gemini image generation prompt for Big Tony, our heavy Landscaper class. He's a burly Italian-American in his 40s, dirty work boots, grass-stained overalls, bandana, thick work gloves. Semi-proportional TF2 style — about 6.5 heads tall with broad shoulders and big hands, but normal head size. Cel-shaded look. I need a character turnaround sheet."*

**Claude outputs something like:**
```
Orthographic character model turnaround sheet showing front view, 
three-quarter view, side profile, and back view of a burly 
Italian-American blue-collar landscaper character, age 40s. 
Semi-proportional stylized 3D game character design, approximately 
6.5 heads tall with broad shoulders and large hands but 
proportional head size. Wearing dirty brown work boots, 
grass-stained olive green overalls over a white t-shirt, red 
bandana on head, thick leather work gloves. Stocky powerful build, 
thick forearms, barrel chest. Friendly but tough facial expression, 
strong jaw, bushy eyebrows, five o'clock shadow. Clean 
cel-shaded/toon-shaded art style with bold outlines, flat color 
bands, stylized lighting. Neutral A-pose, clean white background, 
even flat lighting, no shadows on background. Professional game 
development character concept sheet.
```

**Feed this to Gemini Pro** → Get a clean turnaround sheet PNG.

**Gemini's key strengths for this:**
- Can ingest up to 14 reference images as "identity anchors" for consistency
- Multi-turn editing: *"Keep everything but change the overalls to cargo shorts"*
- Can generate multiple characters while maintaining a consistent art style
- Outputs at 1024×1024 up to 2048×2048

### Step 2: 3D Mesh Generation (HuggingFace Spaces — Free)

Take the Gemini-generated turnaround sheet and upload it to free AI 3D generators:

**Primary: TRELLIS 2** (HuggingFace Space)
- Best geometric fidelity
- Clean quad-approximated surfaces
- Upload the front-view character image
- Download as `.glb`

**Fast backup: TripoSR** (HuggingFace Space)
- Generates in < 0.5 seconds
- Great for rapid iteration ("does this silhouette read well in 3D?")
- Lower quality but useful for prototyping

**Best textures: Hunyuan3D 2.1** (HuggingFace Space)
- Two-stage: geometry + PBR texture synthesis
- Generates Albedo, Normal, and Roughness maps alongside the mesh

**Best for props/weapons: Stable Fast 3D** (HuggingFace Space)
- Built-in UV unwrapping and material delighting
- Great for smaller assets (rakes, nail guns, hard hats)

**AI Retopology: MeshAnything V2** (HuggingFace Space)
- Takes the dense AI mesh → outputs clean low-poly game-ready topology
- Targets artist-style quad meshes at 1K-5K faces
- Run this BEFORE Blender cleanup to save time

> **No local GPU needed!** All of these run on HuggingFace's free ZeroGPU (shared T4/A100). Just upload your image, wait 10-60 seconds, download the `.glb`.

### Step 3: Blender Cleanup (Free)

Budget **5-15 minutes per asset** with these free tools:

**Essential free Blender addons to install:**

| Addon | Source | Purpose |
|-------|--------|---------|
| **RetopoFlow** | [GitHub (CGCookie)](https://github.com/CGCookie/retopoflow) — **free under GPL** | Interactive retopology (draw edge loops, quad patches) |
| **TexTools** | [GitHub (franMarz)](https://github.com/franMarz/TexTools-Blender) | UV rectification, texel density, texture baking |
| **Principled Baker** | [GitHub (danielenger)](https://github.com/danielenger/Principled-Baker) | One-click PBR map baking |
| **Dream Textures** | [GitHub (carson-katri)](https://github.com/carson-katri/dream-textures) | AI texture generation inside Blender |
| **Bsurfaces** | Built-in (enable in Preferences) | Grease pencil → quad topology |
| **Magic UV** | Built-in (enable in Preferences) | Copy/paste UVs, world-space projection |

**Cleanup checklist:**
1. Delete floating geometry fragments (Select All → Select Linked → delete unlinked)
2. Merge by Distance (`M` → merge threshold 0.001)
3. Recalculate Normals (`Shift+N`)
4. Degenerate Dissolve (Mesh → Clean Up)
5. If MeshAnything V2 wasn't sufficient: use RetopoFlow or built-in QuadriFlow Remesh
6. Smart UV Project or TexTools Rectify
7. Bake textures with TexTools / Principled Baker

**Free retopology workflow (no Quad Remesher needed):**
```
Option A (automated): Voxel Remesh → QuadriFlow Remesh (target 5000 faces) 
                       → Shrinkwrap Modifier to snap to original
                       
Option B (semi-auto):  MeshAnything V2 (HuggingFace) → minor Blender fixes

Option C (manual):     RetopoFlow (draw edge loops over the sculpt)
```

### Step 4: Rigging (Free)

**Reallusion AccuRIG** — 100% free standalone app:
1. Import cleaned `.fbx` / `.obj`
2. Place 19 body joint markers + 5 finger markers
3. Test deformation with built-in animations
4. Export as `.fbx` with embedded skeleton and weights

**Why AccuRIG over Mixamo for rigging:** Handles exaggerated/non-standard proportions much better — critical for our semi-proportional TF2-style characters.

### Step 5: Animation (Free)

| Source | Cost | Use For |
|--------|------|---------|
| **Mixamo Library** | Free | Idle, Walk, Run, Jump, Fall, Land, Basic Attacks, Hit Reactions (2,000+ clips) |
| **Cascadeur Free Tier** | Free | Custom combat animations, class-specific moves, physics-corrected motion |
| **Claude Pro** | Included | Write Blender Python scripts for procedural animation adjustments |

Export animations as `FBX Without Skin` → attach to AccuRIG skeleton in Blender → bundle into a single `.glb`.

### Step 6: Godot 4 Import & Shading

1. Drop `.glb` into Godot project
2. Import Dock → Skeleton → Retarget to **Humanoid** BoneMap
3. Save animations into `AnimationLibrary`
4. Apply cel shader (see Section 4)
5. Build `AnimationTree` with `StateMachine` nodes

---

## 4. Godot 4 Cel Shading — Free Options

### 4.1 Option A: Built-in (Zero Addons)

Godot 4 has **native toon shading** built into `StandardMaterial3D`:
- Set `Diffuse Mode` → **Toon**
- Set `Specular Mode` → **Toon**

This gives you hard light banding with zero code and zero addons. Good for prototyping.

### 4.2 Option B: godot4-cel-shader (Recommended)

**[eldskald/godot4-cel-shader](https://github.com/eldskald/godot4-cel-shader)** — Free, open source, actively maintained:
- Customizable light band count and thresholds
- Colored shadows (team-tinted!)
- Specular steps
- Rim lighting
- Inverted hull outlines AND post-process outlines
- Drop-in ready for Godot 4.x

### 4.3 Option C: Custom Shader (Claude Writes It)

Have Claude write you a custom `.gdshader` tailored exactly to your art style. Here's the starter:

```gdshader
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.4, 0.4, 0.55, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.05;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float rim_spread : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = (tex * base_color).rgb;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float intensity = smoothstep(
        shadow_threshold - shadow_softness,
        shadow_threshold + shadow_softness,
        NdotL * ATTENUATION
    );
    vec3 diffuse = mix(shadow_color.rgb * ALBEDO, ALBEDO, intensity) * LIGHT_COLOR;

    float NdotV = 1.0 - dot(NORMAL, VIEW);
    float rim = smoothstep(rim_threshold - 0.05, rim_threshold + 0.05,
        NdotV * pow(NdotL, rim_spread));
    vec3 rim_out = rim * rim_color.rgb * LIGHT_COLOR;

    DIFFUSE_LIGHT += diffuse + rim_out;
}
```

**Outline pass** (apply as `Next Pass` material):
```gdshader
shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.05) = 0.008;

void vertex() {
    VERTEX += NORMAL * outline_thickness;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
```

---

## 5. Essential Free Godot 4 Addons

### 5.1 Must-Have for This Project

| Addon | Source | Purpose | Priority |
|-------|--------|---------|----------|
| **godot4-cel-shader** | [GitHub](https://github.com/eldskald/godot4-cel-shader) | Complete toon shader system with outlines | 🔴 Day 1 |
| **NetFox** | [GitHub](https://github.com/foxssake/netfox) | Authoritative multiplayer: prediction, reconciliation, lag comp | 🔴 Day 1 |
| **LimboAI** | [GitHub](https://github.com/limbonaut/limboai) | Behavior trees + state machines (character logic, NPC AI) | 🟡 Phase 2 |
| **Godot State Charts** | [GitHub](https://github.com/derkork/godot-state-charts) | Visual hierarchical state charts for gameplay states | 🟡 Phase 2 |
| **ProtonScatter** | [GitHub](https://github.com/HungryProton/scatter) | Procedural prop/vegetation/debris scattering for maps | 🟡 Phase 2 |
| **Terrain3D** | [GitHub](https://github.com/TokisanGames/Terrain3D) | High-performance terrain (yards, neighborhoods) | 🟡 Phase 2 |
| **GodotSteam** | [GitHub](https://github.com/GodotSteam/GodotSteam) | Steam lobbies, matchmaking, achievements | 🟠 Phase 4 (launch) |

### 5.2 Nice-to-Have

| Addon | Source | Purpose |
|-------|--------|---------|
| **godot4-vfx-library** | [GitHub](https://github.com/haowg/godot4-vfx-library) | 35+ GPU particle effects (impacts, trails, explosions) |
| **ProtonGraph** | [GitHub](https://github.com/jeancarlo-em/proton-graph) | Node-based procedural mesh creation inside Godot |
| **Godot WFC Generator** | [GitHub](https://github.com/pietru/godot_wfc) | Wave Function Collapse for procedural level chunks |
| **Gaea** | [GitHub](https://github.com/BenjaTK/Gaea) | Procedural generation framework (noise, cellular automata) |
| **CGHEVEN Asset Library** | [Godot AssetLib](https://godotengine.org/asset-library/asset/2722) | Browse and import free 3D models/materials directly in-editor |
| **Ziva** | [ziva.sh](https://ziva.sh) | In-editor AI assistant that inspects scenes and generates code |
| **Godot AI (MCP)** | [Godot AssetLib](https://godotengine.org/asset-library/asset/3389) | Connect Claude/Gemini directly to Godot editor via MCP |

### 5.3 Built-in Godot Features (No Addon Needed)

These are **already in Godot 4** — no downloads required:

| Feature | Where | Notes |
|---------|-------|-------|
| **Toon Diffuse/Specular** | `StandardMaterial3D` → Diffuse Mode: Toon | Basic cel-shading, zero code |
| **Auto LOD on Import** | Mesh import settings (uses meshoptimizer) | Automatic polygon reduction by distance |
| **AnimationTree + StateMachine** | Built-in nodes | Visual state machine for animation blending |
| **MultiplayerSpawner/Synchronizer** | Built-in nodes | Core replication over ENet/WebRTC |
| **NavigationServer3D** | Built-in | AI pathfinding for NPCs |
| **PhysicsServer3D (Jolt)** | Built-in (Godot 4.4+) | Ragdolls, projectiles, debris physics |
| **Visibility Range / HLOD** | `GeometryInstance3D` properties | Distance-based LOD switching with dither fade |

---

## 6. AI Integration with Godot Editor

### 6.1 Godot AI MCP Plugin

The **Godot AI** addon ([AssetLib](https://godotengine.org/asset-library/asset/3389)) turns the Godot editor into an MCP server. This means **Claude (via Antigravity or Claude Desktop) can directly**:
- Inspect your scene tree
- Read and write GDScript files
- Create and modify nodes
- Generate shaders
- Debug errors

### 6.2 Claude + Godot Workflow

You're already in Antigravity, so the workflow is:
1. **Ask Claude (here) to write GDScript** → paste into Godot, or use MCP to push directly
2. **Ask Claude to write shaders** → `.gdshader` files for cel-shading, VFX, water, etc.
3. **Ask Claude to write Blender Python scripts** → batch-process AI meshes (cleanup, retopo, export)
4. **Ask Claude to design procedural generators** → GDScript code that builds houses, fences, props from parameters

### 6.3 Gemini + Art Workflow

1. **Use Claude to write detailed art prompts** → paste into Gemini
2. **Gemini generates character turnarounds, weapon concepts, environment mood boards**
3. **Pin character reference images in Gemini** as "identity anchors" for consistency across sessions
4. **Multi-turn iterate** in Gemini: *"Same character but in a Santa costume"* for seasonal skins

---

## 7. Procedural Generation Strategy

Since you're solo, **procedural generation is your force multiplier**. Use it for:

### 7.1 Map Construction (Claude + Godot)

Have Claude write GDScript procedural generators for:
- **House shells** — Parametric houses from width/depth/stories/roof-type variables
- **Yard layouts** — Fence placement, tree positions, driveway, sidewalk from templates
- **Prop scattering** — ProtonScatter to distribute lawn furniture, garden tools, bushes
- **Roof detail** — Procedural dormer, chimney, and skylight placement

### 7.2 Weapon/Prop Variants

Use Gemini to batch-generate weapon skin concepts, then:
- Feed through AI 3D gen for base meshes
- Claude writes scripts to apply color/material variants procedurally

### 7.3 Terrain (Terrain3D)

- Use Terrain3D for yard terrain (flat lawns, slight slopes, garden beds)
- Paint splatmaps in-editor for grass/dirt/concrete zones
- Procedural foliage instancing for bushes and flowers

---

## 8. Production Schedule (Solo Dev)

### Character Production (Per Character)

| Step | Tool | Time |
|------|------|------|
| Claude writes Gemini prompt | Claude Pro | 5-10 min |
| Gemini generates turnaround sheet | Gemini Pro | 5-15 min (with iteration) |
| Upload to TRELLIS / TripoSR (HuggingFace) | Free | 1-2 min |
| MeshAnything V2 retopology (HuggingFace) | Free | 1-2 min |
| Blender cleanup + UV | Blender + RetopoFlow + TexTools | 30-90 min |
| AI texture touchup | Dream Textures (Blender) | 15-30 min |
| AccuRIG auto-rig | AccuRIG | 15-30 min |
| Mixamo animations | Mixamo | 15-30 min |
| Godot import + shader setup | Godot 4 | 15-30 min |
| **Total per character** | | **~2-5 hours** |
| **All 12 launch characters** | | **~24-60 hours (1-2 weeks)** |

### Full Project Timeline (Solo Dev Estimate)

| Phase | Duration | Focus |
|-------|----------|-------|
| **Phase 1: Vertical Slice** | 3-4 months | 1 map, 4 characters, core combat, basic traversal, toon shader |
| **Phase 2: Alpha** | 4-5 months | All 12 characters, 3 maps, weapons, setup phase, UI |
| **Phase 3: Beta** | 3-4 months | All 6 maps, game modes, progression, audio, netcode polish |
| **Phase 4: Launch** | 2-3 months | Polish, balance, marketing, release |

---

## 9. Quick Reference: The Free Pipeline At a Glance

```
╔══════════════════════════════════════════════════════════════════╗
║                    THE ZERO-BUDGET PIPELINE                     ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  CONCEPT ART                                                     ║
║  ├─ Claude Pro ──────── writes detailed art prompts              ║
║  └─ Gemini Pro ──────── generates turnaround sheets (Imagen 3)   ║
║                                                                  ║
║  3D GENERATION (all free, all on HuggingFace — no GPU needed)    ║
║  ├─ TRELLIS 2 ────────── best quality mesh                       ║
║  ├─ TripoSR ─────────── fastest prototyping (<0.5s)              ║
║  ├─ Hunyuan3D 2.1 ───── best PBR textures                       ║
║  ├─ Stable Fast 3D ──── best for props (built-in UVs)            ║
║  └─ MeshAnything V2 ─── AI retopology (dense → clean game mesh)  ║
║                                                                  ║
║  BLENDER 4 (free + free addons)                                  ║
║  ├─ RetopoFlow ──────── interactive retopology (free on GitHub)  ║
║  ├─ TexTools ────────── UV tools + texture baking                ║
║  ├─ Dream Textures ──── AI texture gen inside Blender            ║
║  └─ Principled Baker ── one-click PBR map baking                ║
║                                                                  ║
║  RIGGING & ANIMATION (free)                                      ║
║  ├─ AccuRIG ─────────── auto-rig (free standalone app)           ║
║  ├─ Mixamo ──────────── 2,000+ free animation clips              ║
║  └─ Cascadeur ───────── AI physics animation (free tier)          ║
║                                                                  ║
║  GODOT 4 (free engine + free addons)                             ║
║  ├─ godot4-cel-shader ── toon shading + outlines                 ║
║  ├─ NetFox ──────────── authoritative multiplayer netcode        ║
║  ├─ ProtonScatter ───── procedural environment scattering        ║
║  ├─ Terrain3D ───────── performant terrain for yards             ║
║  ├─ LimboAI ─────────── behavior trees + state machines          ║
║  ├─ Godot AI (MCP) ──── connect Claude/Gemini to editor         ║
║  └─ Built-in ────────── Toon materials, LOD, AnimationTree,     ║
║                          physics, multiplayer, nav               ║
║                                                                  ║
║  💰 TOTAL ADDITIONAL COST: $0                                    ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

*This addendum is a living document. Update as the pipeline is validated during Phase 1 (Vertical Slice).*

**— END OF ART DIRECTION ADDENDUM v2.0 —**
