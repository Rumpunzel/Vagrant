class_name FightLabStats
extends RefCounted

## Sums up the records of one matchup's fights (see [method FightLabSimulator.simulate]) into what the Fight Lab shows

const OUTCOMES: Array[String] = ["won", "lost", "draw", "fled", "unfinished"]
## Averaged per fight
const MEANS: Array[String] = ["exchanges", "dealt", "taken", "breath_left", "monster_breath_left", "weapon_marks", "shield_marks", "armor_marks"]
## Share of fights in which it happened at least once
const RATES: Array[String] = ["weapon_ruined", "weapon_dropped", "shield_ruined", "shield_dropped", "armor_ruined"]

## { runs, outcomes: {won: share, ...}, means: {...}, rates: {...}, per_exchange: {dealt, taken},
## histograms: {exchanges: {count: fights}, breath_left: {count: fights}} }
static func summarize(records: Array[Dictionary]) -> Dictionary[String, Variant]:
	var runs: int = maxi(records.size(), 1)
	var outcomes: Dictionary[String, float] = {}
	for outcome: String in OUTCOMES: outcomes[outcome] = records.filter(func(record: Dictionary) -> bool: return record["outcome"] == outcome).size() / float(runs)
	var means: Dictionary[String, float] = {}
	for key: String in MEANS: means[key] = _sum(records, key) / float(runs)
	var rates: Dictionary[String, float] = {}
	for key: String in RATES: rates[key] = records.filter(func(record: Dictionary) -> bool: return int(record[key]) > 0).size() / float(runs)
	var total_exchanges: float = maxf(_sum(records, "exchanges"), 1.0)
	return {
		"runs": records.size(),
		"outcomes": outcomes,
		"means": means,
		"rates": rates,
		"per_exchange": {"dealt": _sum(records, "dealt") / total_exchanges, "taken": _sum(records, "taken") / total_exchanges},
		"histograms": {"exchanges": _histogram(records, "exchanges"), "breath_left": _histogram(records, "breath_left")},
	}

static func _sum(records: Array[Dictionary], key: String) -> float:
	var total: float = 0.0
	for record: Dictionary in records: total += float(record[key])
	return total

## Value -> how many fights had it, keyed by the value as text (as JSON keeps it)
static func _histogram(records: Array[Dictionary], key: String) -> Dictionary[String, int]:
	var histogram: Dictionary[String, int] = {}
	for record: Dictionary in records:
		var value: String = str(int(record[key]))
		histogram[value] = histogram.get(value, 0) + 1
	return histogram
