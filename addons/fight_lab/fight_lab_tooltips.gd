@tool
class_name FightLabTooltips
extends RefCounted

## What the Fight Lab's rich tooltips ([RichTooltipTrigger]) say: a pairing's numbers at a glance, a fighter's card, one exchange of a single
## fight, and what the controls and charts mean. Fighters are linked ([code]a:0[/code], [code]b:1[/code]): hovering a name in a locked tooltip
## shows their card, clicking it opens them in the Inspector.

const DIM: Color = Color(1, 1, 1, 0.6)
const LINK: Color = Color(0.55, 0.75, 1.0)

## Explanations of the result sections, by section key
const SECTIONS: Dictionary[String, String] = {
	"outcome": "How the fights ended, as shares of all fights. Outcomes are from side A's view.",
	"cost": "What winning cost side A: injury taken and breath dice spent in the fights it won only. In a pairing's detail: how the outcome spreads over what a fight cost.",
	"damage": "Damage dealt and taken per fight, and side A's breath dice: spent, kept at the end, and how many the foe kept.",
	"length": "How many exchanges a fight lasted, up to the max exchanges of the run.",
	"gear": "Side A's gear: marks gained per fight, and how often a piece was ruined or dropped (dropped gear is picked up after the fight).",
}
## Explanations of the toolbar controls
const CONTROLS: Dictionary[String, String] = {
	"scenario": "[b]Scenario[/b]: who fights whom. Everyone on side A against everyone on side B; characters fight by their side's strategy, monsters as their profile says.",
	"mode": "[b]Many fights[/b]: every pairing, many times each, summed up in the matrix and charts.\n[b]One fight[/b]: a single fight, told exchange by exchange.",
	"fights": "[b]Fights[/b]: how often each pairing (and sweep value) is fought. More fights: steadier numbers, longer runs.",
	"sweep": "[b]Sweep[/b] (optional): fights every pairing once per value of one setting, e.g. side A's Guts from 4 to 10, to see how much it matters.",
	"max_exchanges": "[b]Max exchanges[/b]: a fight still going after this many exchanges counts as unfinished.",
	"seed": "[b]Seed[/b]: the same seed gives the same dice, to compare changes fairly. 0: different dice every run.",
	"pairing": "[b]Pairing[/b]: the fighter of side A and of side B for the one fight.",
}

## The run's result ([method FightLabRun.execute]); the scenario the fighters come from
var result: Dictionary = {}
var scenario: FightLabScenario
## Of a single fight: its exchange log, for [code]exchange:n[/code] links
var exchange_log: Array = []

## A rich tooltip on [param control], from [param content] (() -> String) each time it opens
func attach(control: Control, content: Callable) -> RichTooltipTrigger:
	control.tooltip_text = ""
	var trigger: RichTooltipTrigger = RichTooltipTrigger.new()
	trigger.trigger_node = control
	trigger.content = content
	_link(trigger)
	control.add_child(trigger)
	return trigger

## A tooltip for each link of [param label]
func attach_links(label: RichTextLabel) -> RichTooltipTrigger:
	var trigger: RichTooltipTrigger = RichTooltipTrigger.new()
	trigger.trigger_node = label
	_link(trigger)
	label.add_child(trigger)
	label.meta_clicked.connect(open_link)
	return trigger

func _link(trigger: RichTooltipTrigger) -> void:
	trigger.describe_link = describe_link
	trigger.open_link = open_link
	trigger.describer = self

## [code]a:0[/code] / [code]b:1[/code]: a fighter; [code]exchange:2[/code]: an exchange of the single fight
func describe_link(meta: Variant) -> String:
	var parts: PackedStringArray = str(meta).split(":")
	if parts.size() != 2: return ""
	if parts[0] == "exchange": return describe_exchange(parts[1].to_int())
	return describe_fighter(parts[0], parts[1].to_int())

## A fighter link opens its profile in the Inspector
func open_link(meta: Variant) -> void:
	var parts: PackedStringArray = str(meta).split(":")
	if parts.size() != 2 or parts[0] == "exchange": return
	var profile: ActorProfile = _get_profile(parts[0], parts[1].to_int())
	if profile == null: return
	TooltipManager.force_close_stack()
	EditorInterface.edit_resource(profile)

## A name linked to its fighter card
func link_fighter(side: String, index: int) -> String:
	return "[url=%s:%d][color=%s]%s[/color][/url]" % [side, index, LINK.to_html(), _get_name(side, index)]

## The pairing's numbers at a glance: outcomes, length, what winning cost, gear lost; one line per value with a sweep
func describe_cell(a: int, b: int, cells: Array[Dictionary]) -> String:
	var lines: Array[String] = ["[b]%s[/b] vs [b]%s[/b]" % [link_fighter("a", a), link_fighter("b", b)]]
	if cells.is_empty():
		lines.append("[color=%s]Not fought: a fighter couldn't fight as it is.[/color]" % DIM.to_html())
		return "\n".join(lines)
	if cells.size() == 1: lines.append_array(describe_stats(cells[0]["stats"]))
	else:
		for cell: Dictionary in cells:
			var stats: Dictionary = cell["stats"]
			lines.append("%s %s: %s · %s" % [result.get("sweep", ""), str(cell["value"]), describe_outcomes(stats), describe_median(stats["histograms"]["exchanges"], "exchange")])
	lines.append("[color=%s]Click: this pairing in detail. Ctrl+click: side by side with others.[/color]" % DIM.to_html())
	return "\n".join(lines)

## Outcomes, length, what winning cost, gear lost
static func describe_stats(stats: Dictionary) -> Array[String]:
	var lines: Array[String] = ["%s (%d fights)" % [describe_outcomes(stats), int(stats["runs"])]]
	lines.append("Fight length: %s" % describe_median(stats["histograms"]["exchanges"], "exchange"))
	var won: Dictionary = stats["won"]
	if int(won["runs"]) > 0:
		lines.append("A won fight costs: %s injury, %s breath dice (medians)" % [median(won["histograms"]["taken"]), median(won["histograms"]["breath_spent"])])
	var rates: Dictionary = stats["rates"]
	var lost: Array[String] = []
	for key: String in rates:
		var rate: float = rates[key]
		if rate > 0.0: lost.append("%s %d%%" % [key.replace("_", " "), roundi(rate * 100.0)])
	if not lost.is_empty(): lines.append("Gear lost: %s" % ", ".join(lost))
	return lines

static func describe_outcomes(stats: Dictionary) -> String:
	var parts: Array[String] = []
	var outcomes: Dictionary = stats["outcomes"]
	for outcome: String in FightLabStats.OUTCOMES:
		var share: float = outcomes[outcome]
		if share > 0.0: parts.append("%s %d%%" % [outcome, roundi(share * 100.0)])
	return ", ".join(parts)

static func describe_median(histogram: Dictionary, unit: String) -> String:
	var value: String = median(histogram)
	return "median %s %s%s" % [value, unit, "" if value == "1" else "s"]

static func median(histogram: Dictionary) -> String:
	var percentiles: Array[float] = FightLabStats.percentiles(histogram)
	return str(int(percentiles[2])) if not percentiles.is_empty() else "–"

## A fighter's card: scores, breath dice, gear, and its origins (characters) or attack and tactics (monsters)
func describe_fighter(side: String, index: int) -> String:
	var profile: ActorProfile = _get_profile(side, index)
	if profile == null: return "[b]%s[/b]\n[color=%s]Not in the scenario any more.[/color]" % [_get_name(side, index), DIM.to_html()]
	var monster: MonsterProfile = profile as MonsterProfile
	var lines: Array[String] = ["[b]%s[/b] [color=%s]· %s, side %s[/color]" % [profile.name, DIM.to_html(), "monster" if monster else "character", side.to_upper()]]
	var scores: Array[String] = []
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores.append("%s %d" % [Fight.describe_attribute(attribute), profile.get_attribute_score(attribute)])
	lines.append(" · ".join(scores) + ("" if monster else " [color=%s](rolled; origins may add)[/color]" % DIM.to_html()))
	lines.append("Breath dice: %s" % _describe_dice(monster.get_breath_dice() if monster else Rules.BREATH_DICE))
	lines.append_array(_describe_gear(profile))
	if monster: lines.append_array(_describe_monster(monster))
	else: lines.append_array(_describe_origins(profile as CharacterProfile))
	var strategy: FightLabStrategy = _get_strategy(side, index)
	if strategy and not monster: lines.append(_describe_strategy(strategy))
	lines.append("[color=%s]Click: open it in the Inspector[/color]" % DIM.to_html())
	return "\n".join(lines)

static func _describe_dice(dice: Dictionary) -> String:
	var parts: Array[String] = []
	for die_type: DieType in dice: parts.append("%d × d%d" % [int(dice[die_type]), die_type.faces])
	return ", ".join(parts)

static func _describe_gear(profile: ActorProfile) -> Array[String]:
	var weapons: Array[String] = []
	for weapon: WeaponProfile in profile.weapons: weapons.append("%s (d%d, %s)" % [weapon.name, weapon.die.faces, Fight.describe_attribute(weapon.wield_attribute)])
	var shields: Array[String] = []
	for shield: ShieldProfile in profile.shields: shields.append("%s (d%d, %s)" % [shield.name, shield.die.faces, Fight.describe_attribute(shield.wield_attribute)])
	var armor: Array[String] = []
	for piece: ArmorProfile in profile.armor:
		var parts: Array[String] = []
		if not piece.blocked_results.is_empty(): parts.append("blocks %s" % ", ".join(piece.blocked_results.map(func(result: int) -> String: return str(result))))
		if piece.damage_reduction > 0: parts.append("−%d damage" % piece.damage_reduction)
		armor.append("%s (%s)" % [piece.name, ", ".join(parts)])
	var natural: String = "natural weapons" if profile is MonsterProfile else "unarmed"
	return [
		"Weapons: %s" % (", ".join(weapons) if not weapons.is_empty() else natural),
		"Shield: %s" % (", ".join(shields) if not shields.is_empty() else "none"),
		"Armour: %s" % (", ".join(armor) if not armor.is_empty() else "none"),
	] as Array[String]

static func _describe_monster(monster: MonsterProfile) -> Array[String]:
	var attack: String = Fight.describe_attribute(monster.attack.get_stance())
	if monster.attack.get_nerves_target(): attack += " aimed at %s" % Fight.describe_attribute(monster.attack.get_nerves_target())
	return [
		"Attack: %s" % attack,
		"Tactics: weapon %s; shield %s; armour %s" % [_describe_weapon_tactic(monster.weapon_tactic), _describe_shield_tactic(monster.shield_tactic), "as picked" if monster.armor_tactic else "spares its pieces"],
	] as Array[String]

static func _describe_weapon_tactic(tactic: WeaponTactic) -> String:
	var forcing: ForcingWeaponTactic = tactic as ForcingWeaponTactic
	if tactic == null or (forcing and forcing.max_overshoot == 0 and not forcing.force_marked_faces): return "never forced"
	if forcing == null: return tactic.get_script().get_global_name()
	return "forced up to %d over%s" % [forcing.max_overshoot, ", marked faces too" if forcing.force_marked_faces else ""]

static func _describe_shield_tactic(tactic: ShieldTactic) -> String:
	var forcing: ForcingShieldTactic = tactic as ForcingShieldTactic
	if tactic == null or (forcing and forcing.max_overshoot == 0): return "never forced"
	if forcing == null: return tactic.get_script().get_global_name()
	return "forced up to %d over" % forcing.max_overshoot

static func _describe_strategy(strategy: FightLabStrategy) -> String:
	var breath_dice: String = "all in"
	match strategy.breath_dice:
		FightLabStrategy.BreathDiceChoice.SAFE: breath_dice = "only those that can't be lost"
		FightLabStrategy.BreathDiceChoice.SAFE_PLUS_RISKY: breath_dice = "the safe ones and the %d smallest that can be lost" % strategy.risky_dice
	var parts: Array[String] = [
		"stance %s" % (Fight.describe_attribute(strategy.stance) if strategy.stance else "favoured"),
		"breath dice %s" % breath_dice,
		"weapon %s" % _describe_weapon_tactic(strategy.weapon_tactic),
		"shield %s" % _describe_shield_tactic(strategy.shield_tactic),
	]
	if strategy.flee_at_breath_dice > 0: parts.append("flees at %d breath dice" % strategy.flee_at_breath_dice)
	return "[b]Strategy %s[/b]: %s" % [strategy.get_label(), "; ".join(parts)]

static func _describe_origins(profile: CharacterProfile) -> Array[String]:
	var lines: Array[String] = []
	for origin: Origin in profile.origins:
		if origin == null: continue
		var abilities: Array[String] = []
		for ability: Ability in origin.abilities:
			if not ability.description.is_empty(): abilities.append(ability.description)
		lines.append("[b]%s[/b]%s" % [origin.name, (": " + " ".join(abilities)) if not abilities.is_empty() else ""])
	return lines

## One exchange of the single fight: both threats, then breath dice and injuries after it
func describe_exchange(number: int) -> String:
	if number < 1 or number > exchange_log.size(): return ""
	var entry: Dictionary = exchange_log[number - 1]
	var fight: Dictionary = result.get("fight", {})
	var a: String = _get_name("a", int(fight.get("a", 0)))
	var b: String = _get_name("b", int(fight.get("b", 0)))
	return "\n".join([
		"[b]Exchange %d[/b]" % number,
		"Threat: %s %d, %s %d" % [a, int(entry["threat"]), b, int(entry["foe_threat"])],
		"After it: %s %d breath dice and %d injury, %s %d breath dice and %d injury" % [a, int(entry["breath"]), int(entry["injuries"]), b, int(entry["foe_breath"]), int(entry["foe_injuries"])],
	] as Array[String])

func _get_name(side: String, index: int) -> String:
	var names: Array = result.get("side_" + side, [])
	return str(names[index]) if index >= 0 and index < names.size() else "?"

## The profile behind a name of the result, if the scenario still has it there
func _get_profile(side: String, index: int) -> ActorProfile:
	if scenario == null: return null
	if side == "a":
		if index < 0 or index >= scenario.get_row_count() or scenario.get_row_name(index) != _get_name(side, index): return null
		return scenario.get_row_profile(index)
	if index < 0 or index >= scenario.side_b.size() or scenario.side_b[index] == null: return null
	return scenario.side_b[index] if scenario.side_b[index].name == _get_name(side, index) else null

## How the profile behind a name fights, if it is a character
func _get_strategy(side: String, index: int) -> FightLabStrategy:
	if side == "a": return scenario.get_row_strategy(index)
	return scenario.strategy_b if scenario.strategy_b else FightLabStrategy.new()
