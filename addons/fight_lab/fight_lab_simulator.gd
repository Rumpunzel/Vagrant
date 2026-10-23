class_name FightLabSimulator
extends RefCounted

## Plays whole fights through the game's own [Fight], deciding for the player as a [FightLabStrategy] says.
## Returns one record per fight (see [method simulate]).

const OUTCOMES: Dictionary[Fight.Outcome, String] = {
	Fight.Outcome.ONGOING: "unfinished",
	Fight.Outcome.WON: "won",
	Fight.Outcome.LOST: "lost",
	Fight.Outcome.DRAW: "draw",
	Fight.Outcome.FLED: "fled",
}

var _character_scene: PackedScene = load("uid://bl0pdxri24fnh")  # character.tscn
var _monster_scene: PackedScene = load("uid://kmifqq0ejuri")  # monster.tscn
## Characters and monsters are nodes and need a parent while they fight
var _parent: Node

func _init(parent: Node) -> void:
	assert(parent)
	_parent = parent

## One fight from full breath and fresh gear: outcome, exchanges, damage, breath spent and left, and what happened to the gear.
## With [param with_log], "log" holds one entry per exchange: what was told, both threats, breath dice and injuries after it.
func simulate(matchup: FightLabMatchup, max_exchanges: int, with_log: bool = false) -> Dictionary[String, Variant]:
	var character: Character = _character_scene.instantiate()
	_parent.add_child(character)
	character.character_profile = matchup.character_profile
	var monster: Monster = _monster_scene.instantiate()
	_parent.add_child(monster)
	monster.monster_profile = matchup.monster_profile
	var gear_before: Dictionary[String, int] = _count_gear(character)
	var breath_start: int = character.get_breath_dice_count()
	var exchange_log: Array[Dictionary] = []
	var fight: Fight = Fight.new(AdventureFightDecision.new(), character, monster)
	var dealt: int = 0
	var taken: int = 0
	var weapon_dropped: bool = false
	var shield_dropped: bool = false
	while fight.is_ongoing() and fight.get_exchange_count() < max_exchanges:
		_play_exchange(fight, matchup.strategy)
		var exchange: FightExchange = fight.get_last_exchange()
		dealt += exchange.second.injury_taken
		taken += exchange.first.injury_taken
		weapon_dropped = weapon_dropped or exchange.first.weapon_dropped
		shield_dropped = shield_dropped or exchange.first.shield_dropped
		if with_log: exchange_log.append({
			"text": fight.get_exchange_summary(),
			"threat": exchange.first.threat,
			"monster_threat": exchange.second.threat,
			"breath": character.get_breath_dice_count(),
			"monster_breath": monster.get_breath_dice_count(),
			"injuries": character.get_injury_total(),
			"monster_injuries": monster.get_injury_total(),
		})
	var record: Dictionary[String, Variant] = {
		"outcome": OUTCOMES[fight.outcome],
		"exchanges": fight.get_exchange_count(),
		"dealt": dealt,
		"taken": taken,
		"breath_left": character.get_breath_dice_count(),
		"breath_spent": breath_start - character.get_breath_dice_count(),
		"monster_breath_left": monster.get_breath_dice_count(),
		"weapon_dropped": weapon_dropped,
		"shield_dropped": shield_dropped,
	}
	var gear_after: Dictionary[String, int] = _count_gear(character)
	for key: String in gear_after: record[key] = gear_after[key] - gear_before[key]
	if with_log: record["log"] = exchange_log
	character.free()
	monster.free()
	return record

func _play_exchange(fight: Fight, strategy: FightLabStrategy) -> void:
	var character: Character = fight.protagonist
	var request: FightRequest = fight.create_request(strategy.flee_at_breath_dice > 0 and character.get_breath_dice_count() <= strategy.flee_at_breath_dice)
	if request.has_stance_choice() and strategy.stance: request.attribute = strategy.stance
	request.nerves_target = strategy.nerves_target if strategy.nerves_target else Rules.STRENGTH
	request.selected_breath_dice = _select_breath_dice(character, request.attribute, strategy)
	fight.start_exchange_from(request.roll())
	# Before any step: the tactics commit and pick armour as the player would
	fight.resolve_player_choice(func(player: FightSide) -> void:
		player.weapon_tactic = strategy.weapon_tactic
		player.shield_tactic = strategy.shield_tactic
		player.armor_tactic = strategy.armor_tactic
	)
	while fight.is_exchange_pending():
		var step: ExchangeStep = fight.get_current_step()
		fight.advance()
		if step is IncapacitationStep and step.is_player(): (step as IncapacitationStep).resolve(fight, _save(fight, step as IncapacitationStep, strategy))
	fight.end_exchange()

func _select_breath_dice(character: Character, attribute: CharacterAttribute, strategy: FightLabStrategy) -> Dictionary[DieType, int]:
	if strategy.breath_dice == FightLabStrategy.BreathDiceChoice.ALL_IN: return character.breath_dice.duplicate()
	var selected: Dictionary[DieType, int] = character.get_auto_selected_breath_dice(attribute)
	if selected.values().any(func(amount: int) -> bool: return amount > 0): return selected
	var smallest: DieType = null
	for die_type: DieType in character.breath_dice:
		if character.breath_dice[die_type] > 0 and (not smallest or die_type.faces < smallest.faces): smallest = die_type
	return {smallest: 1}

## Rolls the Guts save all in, as the save page would, unless the strategy gives in
func _save(fight: Fight, step: IncapacitationStep, strategy: FightLabStrategy) -> bool:
	if strategy.gives_in: return false
	var decision: AdventureSaveDecision = AdventureSaveDecision.new()
	decision.attribute = Rules.STRENGTH
	decision.difficulty = step.get_difficulty(fight)
	var request: SaveRequest = SaveRequest.new(fight.protagonist, Rules.STRENGTH, decision)
	request.selected_breath_dice = fight.protagonist.breath_dice.duplicate()
	var result: SaveResult = request.roll()
	fight.protagonist.parse_dice_result(result)
	return result.is_success()

## Marks and ruined pieces per kind of gear
static func _count_gear(character: Character) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	_count(counts, "weapon", character.weapons)
	_count(counts, "shield", character.shields)
	_count(counts, "armor", character.armor)
	return counts

static func _count(counts: Dictionary[String, int], kind: String, equipment: Array) -> void:
	counts[kind + "_marks"] = 0
	counts[kind + "_ruined"] = 0
	for piece: Equipment in equipment:
		counts[kind + "_marks"] += piece.marked_faces.size()
		counts[kind + "_ruined"] += int(piece.ruined)
