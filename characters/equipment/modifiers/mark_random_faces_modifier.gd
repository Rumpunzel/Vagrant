class_name MarkRandomFacesModifier
extends EquipmentModifier

## Marks [member count] different random faces.
## Never marks more faces than there are, so it never ruins anything.

@export_range(1, 12) var count: int = 2

func modify(equipment: Equipment) -> void:
	var unmarked_faces: Array[int] = []
	for face: int in equipment.get_markable_faces(): if not equipment.is_marked(face): unmarked_faces.append(face)
	unmarked_faces.shuffle()
	for face: int in unmarked_faces.slice(0, count): equipment.mark(face)
