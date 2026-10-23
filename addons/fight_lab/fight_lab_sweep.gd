@tool
@abstract
class_name FightLabSweep
extends Resource

## One parameter the Fight Lab varies: every matchup is simulated once per value

@export var from: int = 1
@export var to: int = 12

func get_values() -> Array[int]:
	var values: Array[int] = []
	values.assign(range(from, to + 1))
	return values

## What is varied, e.g. "Character Guts"
@abstract func get_label() -> String
## Changes copies of the matchup's profiles or strategy for [param value]; never the originals
@abstract func apply(value: int, matchup: FightLabMatchup) -> void
