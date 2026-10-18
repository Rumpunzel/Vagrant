class_name MarkRandomFacesModifier
extends WeaponModifier

## Marks [member count] different random faces, e.g. for a battered weapon.
## Never marks more faces than the die has, so it never ruins a weapon.

@export_range(1, 12) var count: int = 2

func modify(weapon: Weapon) -> void:
	var unmarked_faces: Array[int] = []
	for face: int in range(1, weapon.get_die_type().faces + 1): if not weapon.is_marked(face): unmarked_faces.append(face)
	unmarked_faces.shuffle()
	for face: int in unmarked_faces.slice(0, count): weapon.mark(face)
