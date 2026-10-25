@abstract
class_name Equipment
extends Resource

## Weapons, armour and shields as carried: faces get marked; with no face left to mark, the item is ruined for good.

@export var marked_faces: Array[int] = []
@export var ruined: bool = false
## Lost to the foe's Nerves: unusable until the fight is over
var dropped: bool = false

## Faces that can be marked: a weapon's die faces, the results a piece of armour blocks
@abstract func get_markable_faces() -> Array[int]
@abstract func get_equipment_name() -> String

## Marks [param face], or the next higher unmarked face if it already is. Returns the face marked; 0 when none was left, which ruins the item.
func mark(face: int) -> int:
	assert(not ruined)
	assert(get_markable_faces().has(face))
	var target: int = _get_mark_target(face, marked_faces)
	if target == 0: ruined = true
	else:
		marked_faces.append(target)
		marked_faces.sort()
	emit_changed()
	return target

func ruin() -> void:
	ruined = true
	emit_changed()

func mark_all() -> void:
	assert(not ruined)
	marked_faces = get_markable_faces().duplicate()
	marked_faces.sort()
	emit_changed()

## The faces [param times] calls of [method mark] on [param face] would mark, without marking them; ends with 0 if that ruins the item
func preview_marks(face: int, times: int) -> Array[int]:
	var marked: Array[int] = marked_faces.duplicate()
	var faces: Array[int] = []
	for _index: int in times:
		var target: int = _get_mark_target(face, marked)
		faces.append(target)
		if target == 0: break
		marked.append(target)
	return faces

func get_unmarked_count() -> int: return get_markable_faces().size() - marked_faces.size()

func is_usable() -> bool: return not ruined and not dropped
func is_marked(face: int) -> bool: return marked_faces.has(face)

## [param face], or the next higher face not in [param marked]; 0 when none is left
func _get_mark_target(face: int, marked: Array[int]) -> int:
	if not marked.has(face): return face
	var target: int = 0
	for markable_face: int in get_markable_faces():
		if markable_face > face and not marked.has(markable_face) and (target == 0 or markable_face < target): target = markable_face
	return target

func _set_state(new_marked_faces: Array[int], new_ruined: bool) -> void:
	marked_faces = new_marked_faces.duplicate()
	marked_faces.sort()
	ruined = new_ruined
