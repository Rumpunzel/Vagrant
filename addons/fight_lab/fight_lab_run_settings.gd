@tool
class_name FightLabRunSettings
extends Resource

## How the Fight Lab dock runs a [FightLabScenario]; saved by the dock so its child process can read it, and kept for next time

enum Mode {
	## Everyone on side A against everyone on side B, [member fights] times each
	MANY_FIGHTS,
	## One fight between [member a] and [member b], told exchange by exchange
	ONE_FIGHT,
}

@export var scenario: FightLabScenario
@export var mode: Mode = Mode.MANY_FIGHTS
@export_range(1, 10000) var fights: int = 300
## A fight still going after this many exchanges counts as unfinished
@export_range(1, 200) var max_exchanges: int = 50
## 0: a different seed every time
@export var random_seed: int = 0
## Optional: every matchup is simulated once per value
@export var sweep: FightLabSweep
## Indices into the scenario's sides, for [constant ONE_FIGHT]
@export var a: int = 0
@export var b: int = 0
## Result sections the dock shows
@export var sections: Array[String] = []
