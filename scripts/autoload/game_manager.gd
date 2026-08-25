# ============================================================
# ROOFERS vs LANDSCAPERS — Game Manager (Autoload Singleton)
# ============================================================
# Central game state manager. Handles match flow, round logic,
# game modes, and phase transitions.
#
# Loaded as autoload "GameManager" in project.godot.
extends Node

## Emitted when the game phase changes (setup, assault, overtime, etc.)
signal phase_changed(new_phase: GamePhase)
## Emitted when a round ends
signal round_ended(winning_team: Team)
## Emitted when the full match ends
signal match_ended(winning_team: Team)
## Emitted every second during gameplay with remaining time
signal timer_tick(seconds_remaining: float)

# --- Enums ---

enum Team {
	NONE,
	ROOFERS,
	LANDSCAPERS
}

enum GamePhase {
	LOBBY,          ## Waiting for players
	SETUP,          ## Roofers place defenses (30-60s)
	ASSAULT,        ## Main combat phase (3-5 min)
	OVERTIME,       ## Triggered if Landscapers breach at timer end
	ROUND_END,      ## Scoring / recap
	MATCH_END       ## Final results
}

enum GameMode {
	KING_OF_THE_ROOF,   ## Core mode: eliminate all Roofers or hold all zones
	TICKET_BRAWL,       ## TDM with respawn tickets
	OVERTIME_MADNESS,   ## Always goes to overtime with shrinking roof
	GRUDGE_MATCH        ## 1v1 / 2v2 deathmatch
}

# --- Configuration ---

## Current game mode
var current_mode: GameMode = GameMode.KING_OF_THE_ROOF

## Current phase
var current_phase: GamePhase = GamePhase.LOBBY

## Which team is defending (on the roof) this round
var defending_team: Team = Team.ROOFERS

## Which team is attacking this round
var attacking_team: Team = Team.LANDSCAPERS

## Current round number (1-indexed)
var current_round: int = 1

## Total rounds in this match (best of N)
var total_rounds: int = 3

## Round wins per team
var round_wins: Dictionary = {
	Team.ROOFERS: 0,
	Team.LANDSCAPERS: 0
}

## Phase timer (seconds remaining)
var phase_timer: float = 0.0

## Is the game clock running
var timer_active: bool = false

# --- Phase Durations (configurable per mode) ---

const SETUP_DURATION: float = 45.0
const ASSAULT_DURATION: float = 240.0  # 4 minutes
const OVERTIME_DURATION: float = 60.0
const ROUND_END_DURATION: float = 8.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if timer_active and phase_timer > 0.0:
		phase_timer -= delta
		timer_tick.emit(phase_timer)
		if phase_timer <= 0.0:
			phase_timer = 0.0
			_on_phase_timer_expired()


# --- Public API ---

## Start a new match with the given mode
func start_match(mode: GameMode = GameMode.KING_OF_THE_ROOF) -> void:
	current_mode = mode
	current_round = 1
	round_wins = { Team.ROOFERS: 0, Team.LANDSCAPERS: 0 }
	defending_team = Team.ROOFERS
	attacking_team = Team.LANDSCAPERS
	_start_round()


## Transition to a new game phase
func set_phase(new_phase: GamePhase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)

	match new_phase:
		GamePhase.SETUP:
			phase_timer = SETUP_DURATION
			timer_active = true
		GamePhase.ASSAULT:
			phase_timer = ASSAULT_DURATION
			timer_active = true
		GamePhase.OVERTIME:
			phase_timer = OVERTIME_DURATION
			timer_active = true
		GamePhase.ROUND_END:
			phase_timer = ROUND_END_DURATION
			timer_active = true
		_:
			timer_active = false


## Call when a team achieves a round victory
func declare_round_winner(winner: Team) -> void:
	timer_active = false
	round_wins[winner] += 1
	round_ended.emit(winner)

	# Check for match winner (best of N)
	var wins_needed: int = ceili(total_rounds / 2.0)
	if round_wins[winner] >= wins_needed:
		set_phase(GamePhase.MATCH_END)
		match_ended.emit(winner)
	else:
		set_phase(GamePhase.ROUND_END)


# --- Internal ---

func _start_round() -> void:
	set_phase(GamePhase.SETUP)


func _on_phase_timer_expired() -> void:
	match current_phase:
		GamePhase.SETUP:
			set_phase(GamePhase.ASSAULT)
		GamePhase.ASSAULT:
			# Time's up — Roofers survive, they win the round
			# (unless Landscapers are on roof → trigger overtime)
			# TODO: Check if any Landscaper is on the roof for overtime
			declare_round_winner(defending_team)
		GamePhase.OVERTIME:
			# Overtime expired — whoever has more players wins
			# TODO: Count remaining players
			declare_round_winner(defending_team)
		GamePhase.ROUND_END:
			# Swap teams for next round
			_swap_teams()
			current_round += 1
			_start_round()


func _swap_teams() -> void:
	var temp := defending_team
	defending_team = attacking_team
	attacking_team = temp
