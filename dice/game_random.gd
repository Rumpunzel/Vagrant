class_name GameRandom
extends RefCounted

## The one random generator for everything that changes the game (dice, chances, marked faces), so a run can be repeated from its seed
## and continued from a save's [method get_state]. Cosmetic randomness (sounds, UI) uses Godot's global one, so it can't shift results.
## No dependencies: [DieType] (preloaded by [code]Rules[/code]) uses it.

static var _rng: RandomNumberGenerator = _create()

## Starts a new sequence; [param new_seed] 0: a random one
static func start(new_seed: int = 0) -> void:
	_rng = _create()
	if new_seed != 0: _rng.seed = new_seed

static func get_seed() -> int: return _rng.seed
static func get_state() -> int: return _rng.state
static func set_state(state: int) -> void: _rng.state = state

static func range_int(from: int, to: int) -> int: return _rng.randi_range(from, to)

## [param times] out of [param out_of]
static func chance(times: int, out_of: int) -> bool: return range_int(1, out_of) <= times

static func shuffle(array: Array) -> void:
	for index: int in range(array.size() - 1, 0, -1):
		var other: int = range_int(0, index)
		var swapped: Variant = array[index]
		array[index] = array[other]
		array[other] = swapped

static func _create() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng
