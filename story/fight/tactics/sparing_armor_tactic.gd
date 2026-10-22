class_name SparingArmorTactic
extends ArmorTactic

## Wears down the piece with the most unmarked results, and marks rather than ruins

func pick(options: Array[ArmorPick]) -> ArmorPick:
	var chosen: ArmorPick = null
	for option: ArmorPick in options:
		if not chosen or _rank(option) > _rank(chosen): chosen = option
	return chosen

static func _rank(option: ArmorPick) -> int:
	if option.ruin: return -1
	return option.piece.get_markable_faces().filter(func(face: int) -> bool: return not option.piece.is_marked(face)).size()
