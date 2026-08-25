# ============================================================
# ROOFERS vs LANDSCAPERS — Team Manager (Autoload Singleton)
# ============================================================
# Manages team assignments, class definitions, and team-specific
# visual properties (shader colors, UI colors).
#
# Loaded as autoload "TeamManager" in project.godot.
extends Node

## Emitted when a player is assigned to a team
signal player_assigned(player_id: int, team: GameManager.Team)

# --- Team Visual Properties ---
# These define the shader uniform overrides per team

const TEAM_COLORS: Dictionary = {
	GameManager.Team.ROOFERS: {
		"display_name": "Roofers",
		"shadow_color": Color(0.35, 0.30, 0.50, 1.0),    # Cool purple-blue
		"rim_color": Color(1.0, 0.85, 0.5, 1.0),          # Warm gold
		"outline_color": Color(0.1, 0.05, 0.15, 1.0),     # Dark purple
		"ui_color": Color(0.95, 0.55, 0.2, 1.0),          # Orange
		"ui_color_dark": Color(0.6, 0.3, 0.1, 1.0),       # Dark orange
	},
	GameManager.Team.LANDSCAPERS: {
		"display_name": "Landscapers",
		"shadow_color": Color(0.25, 0.40, 0.30, 1.0),     # Earthy green
		"rim_color": Color(0.5, 1.0, 0.6, 1.0),           # Bright green
		"outline_color": Color(0.05, 0.12, 0.05, 1.0),    # Dark green
		"ui_color": Color(0.3, 0.75, 0.35, 1.0),          # Green
		"ui_color_dark": Color(0.15, 0.45, 0.18, 1.0),    # Dark green
	}
}

# --- Class Definitions ---
# Each class has base stats and references to resources.
# These will be expanded as we build out each character.

enum RooferClass {
	FOREMAN,        ## "Boss Man" — Tank / Heavy
	NAILER,         ## "Tack" — DPS / Light
	TAR_KING,       ## "Sticky" — Area Denial
	SHINGLE_SLINGER,## "Frisbee" — Ranged
	GUTTER_SNIPER,  ## "Downspout" — Sniper
	CLEANUP_GUY,    ## "The Spy" — Infiltrator
	APPRENTICE,     ## "Rookie" — Support
	MAG_SWEEP,      ## "Scrap" — Defender / Reflector
	ELECTRICIAN,    ## "Sparky" — Trapper / DPS
	HVAC_TECH       ## "Freon" — Heavy / Control
}

enum LandscaperClass {
	GARDENER,       ## "Sprout" — DPS / Light
	LUMBERJACK,     ## "Chop" — Heavy / Siege
	BOTANIST,       ## "Flora" — Support
	MOWER,          ## "Big Tony" — Tank / Mech
	TRIMMER,        ## "Hedge" — Flanker
	BLOWER,         ## "Gust" — Crowd Control
	RAKER,          ## "Scratch" — Trapper
	SPRINKLER,      ## "Splash" — Area Control
	CLIMBER,        ## "Spider" — Scout
	HOBBYIST        ## "Buzz" — Air Support
}

# Base stats template for all classes
# Will be loaded from resource files as classes are built
const BASE_STATS: Dictionary = {
	"health": 100.0,
	"move_speed": 6.0,
	"sprint_multiplier": 1.5,
	"jump_force": 8.0,
}

# --- Player Roster ---
# Maps player_id -> { team, class, stats }
var players: Dictionary = {}


func _ready() -> void:
	pass


# --- Public API ---

## Assign a player to a team
func assign_player(player_id: int, team: GameManager.Team) -> void:
	if player_id not in players:
		players[player_id] = {}
	players[player_id]["team"] = team
	player_assigned.emit(player_id, team)


## Get team color properties for shader uniforms
func get_team_visuals(team: GameManager.Team) -> Dictionary:
	if team in TEAM_COLORS:
		return TEAM_COLORS[team]
	return {}


## Apply team colors to a character's shader material
func apply_team_shader(mesh: MeshInstance3D, team: GameManager.Team) -> void:
	var visuals := get_team_visuals(team)
	if visuals.is_empty():
		return

	var mat := mesh.get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("shadow_color", visuals["shadow_color"])
		mat.set_shader_parameter("rim_color", visuals["rim_color"])

	# Apply outline color to the Next Pass material
	var outline_mat := mat.next_pass if mat else null
	if outline_mat is ShaderMaterial:
		outline_mat.set_shader_parameter("outline_color", visuals["outline_color"])


## Get all players on a given team
func get_team_players(team: GameManager.Team) -> Array[int]:
	var result: Array[int] = []
	for player_id in players:
		if players[player_id].get("team") == team:
			result.append(player_id)
	return result


## Get the display name for a team
func get_team_name(team: GameManager.Team) -> String:
	var visuals := get_team_visuals(team)
	return visuals.get("display_name", "Unknown")
