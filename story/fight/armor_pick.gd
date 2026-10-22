class_name ArmorPick
extends RefCounted

## Which piece of armour takes a blocked blow, and whether it is ruined instead of marking its next higher result

var piece: Armor
var ruin: bool

func _init(with_piece: Armor, ruins_it: bool = false) -> void:
	piece = with_piece
	ruin = ruins_it

## What the defender may pick for a blocked [param result]: a piece whose fitting result is unmarked;
## if every fitting result is marked, any fitting piece, marking its next higher result (if it has one) or ruined
static func get_options(armor: Array[Armor], result: int) -> Array[ArmorPick]:
	var fitting: Array[Armor] = []
	fitting.assign(armor.filter(func(candidate: Armor) -> bool: return candidate.blocks(result)))
	var options: Array[ArmorPick] = []
	for candidate: Armor in fitting: if not candidate.is_marked(result): options.append(ArmorPick.new(candidate))
	if not options.is_empty(): return options
	for candidate: Armor in fitting:
		if candidate.get_markable_faces().any(func(face: int) -> bool: return face > result and not candidate.is_marked(face)): options.append(ArmorPick.new(candidate))
		options.append(ArmorPick.new(candidate, true))
	return options
