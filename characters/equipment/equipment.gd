@abstract
class_name Equipment
extends Resource

## Weapons and armour as carried: faces get marked, marking a marked face ruins it.

enum Mark {
	MARKED,
	RUINED,
}

@export var marked_faces: Array[int] = []
@export var ruined: bool = false

## Faces that can be marked: a weapon's die faces, the results a piece of armour blocks
@abstract func get_markable_faces() -> Array[int]
@abstract func get_equipment_name() -> String

func mark(face: int) -> Mark:
	assert(not ruined)
	assert(get_markable_faces().has(face))
	if marked_faces.has(face):
		ruined = true
		emit_changed()
		return Mark.RUINED
	marked_faces.append(face)
	marked_faces.sort()
	emit_changed()
	return Mark.MARKED

func is_usable() -> bool: return not ruined
func is_marked(face: int) -> bool: return marked_faces.has(face)

func _set_state(new_marked_faces: Array[int], new_ruined: bool) -> void:
	marked_faces = new_marked_faces.duplicate()
	marked_faces.sort()
	ruined = new_ruined
