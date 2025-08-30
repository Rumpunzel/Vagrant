@tool
class_name OriginCombination
extends Background

@export var origins: Array[Origin]

static func find_combination(selected_origins: Array[Origin]) -> OriginCombination:
	var combination_files: Array[String] = Rules.list_all_files("res://characters/origins/combinations/", false, func(file_name: String) -> bool: return file_name.get_extension() == "tres")
	var combinations: Array[OriginCombination] = []
	combinations.assign(combination_files.map(func(origin_combination_file: String) -> OriginCombination: return load(origin_combination_file)))
	for combination: OriginCombination in combinations:
		if combination.fits(selected_origins): return combination
	return null

func fits(selected_origins: Array[Origin]) -> bool:
	for origin: Origin in origins: if not selected_origins.has(origin): return false
	return true
