class_name FightLabStats
extends RefCounted

## Sums up the records of one matchup's fights (see [method FightLabSimulator.simulate]) into what the Fight Lab shows

const OUTCOMES: Array[String] = ["won", "lost", "draw", "fled", "unfinished"]
## Per fight: averaged, and counted per value
const NUMBERS: Array[String] = ["exchanges", "dealt", "taken", "breath_left", "breath_spent", "foe_breath_left", "weapon_marks", "shield_marks", "armor_marks"]
## Share of fights in which it happened at least once
const RATES: Array[String] = ["weapon_ruined", "weapon_dropped", "shield_ruined", "shield_dropped", "armor_ruined"]
## What winning cost, over the fights won only
const WIN_COSTS: Array[String] = ["taken", "breath_spent"]
## Counted per value and outcome: how the outcome depends on fight length and cost
const BY_OUTCOME: Array[String] = ["exchanges", "taken", "breath_spent"]

## { runs, outcomes: {won: share, ...}, means: {...}, histograms: {key: {value: fights}}, rates: {...},
## won: {runs, means: {taken, breath_spent}, histograms: {...}}, by_outcome: {key: {outcome: {value: fights}}} }.
## Histogram values are text, as JSON keeps them.
static func summarize(records: Array[Dictionary]) -> Dictionary[String, Variant]:
	var outcomes: Dictionary[String, float] = {}
	for outcome: String in OUTCOMES: outcomes[outcome] = _share(records, func(record: Dictionary) -> bool: return record["outcome"] == outcome)
	var rates: Dictionary[String, float] = {}
	for key: String in RATES: rates[key] = _share(records, func(record: Dictionary) -> bool: return int(record[key]) > 0)
	var won: Array[Dictionary] = []
	won.assign(records.filter(func(record: Dictionary) -> bool: return record["outcome"] == "won"))
	return {
		"runs": records.size(),
		"outcomes": outcomes,
		"means": _means(records, NUMBERS),
		"histograms": _histograms(records, NUMBERS),
		"rates": rates,
		"won": {"runs": won.size(), "means": _means(won, WIN_COSTS), "histograms": _histograms(won, WIN_COSTS)},
		"by_outcome": _by_outcome(records),
	}

static func _by_outcome(records: Array[Dictionary]) -> Dictionary[String, Dictionary]:
	var by_outcome: Dictionary[String, Dictionary] = {}
	for key: String in BY_OUTCOME: by_outcome[key] = {}
	for outcome: String in OUTCOMES:
		var of_outcome: Array[Dictionary] = []
		of_outcome.assign(records.filter(func(record: Dictionary) -> bool: return record["outcome"] == outcome))
		var histograms: Dictionary[String, Dictionary] = _histograms(of_outcome, BY_OUTCOME)
		for key: String in BY_OUTCOME: by_outcome[key][outcome] = histograms[key]
	return by_outcome

static func _share(records: Array[Dictionary], counts: Callable) -> float:
	if records.is_empty(): return 0.0
	return records.filter(counts).size() / float(records.size())

static func _means(records: Array[Dictionary], keys: Array[String]) -> Dictionary[String, float]:
	var means: Dictionary[String, float] = {}
	for key: String in keys:
		var total: float = 0.0
		for record: Dictionary in records: total += float(record[key])
		means[key] = total / records.size() if not records.is_empty() else 0.0
	return means

static func _histograms(records: Array[Dictionary], keys: Array[String]) -> Dictionary[String, Dictionary]:
	var histograms: Dictionary[String, Dictionary] = {}
	for key: String in keys:
		var histogram: Dictionary[String, int] = {}
		for record: Dictionary in records:
			var value: String = str(int(record[key]))
			histogram[value] = histogram.get(value, 0) + 1
		histograms[key] = histogram
	return histograms
