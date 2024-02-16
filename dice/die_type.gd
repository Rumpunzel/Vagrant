class_name DieType
extends Resource

signal rolled(die_type: Die, result: int)

@export var icon: Texture
@export var faces := 12

func roll() -> int:
	var result := randi_range(1, faces)
	rolled.emit(self, result)
	return result

func get_die() -> Die:
	return Die.new(self)

func get_dice_pool(amount: int) -> Array[Die]:
	var dice_pool: Array[Die] = [ ]
	for _index in range(amount):
		dice_pool.append(get_die())
	return dice_pool

func _to_string() -> String:
	return "d%d" % faces
