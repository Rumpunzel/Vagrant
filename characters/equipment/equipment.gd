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
	var target: int = face
	if marked_faces.has(face):
		target = 0
		for markable_face: int in get_markable_faces():
			if markable_face > face and not marked_faces.has(markable_face) and (target == 0 or markable_face < target): target = markable_face
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

func is_usable() -> bool: return not ruined and not dropped
func is_marked(face: int) -> bool: return marked_faces.has(face)

func _set_state(new_marked_faces: Array[int], new_ruined: bool) -> void:
	marked_faces = new_marked_faces.duplicate()
	marked_faces.sort()
	ruined = new_ruined
