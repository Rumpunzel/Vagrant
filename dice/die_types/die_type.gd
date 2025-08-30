@tool
class_name DieType
extends Resource

signal rolled(die_type: Die, result: int, roll_sound: AudioStream)

@export var icon: Texture
@export var faces: int = 12
@export var roll_sound: AudioStream

func roll(play_sound: bool) -> int:
	var result: int = randi_range(1, faces)
	rolled.emit(self, result, roll_sound if play_sound else null)
	return result

func get_die() -> Die:
	var new_die: Die = Die.new()
	new_die.die_type = self
	return new_die

func get_dice_pool(amount: int) -> Array[Die]:
	var dice_pool: Array[Die] = [ ]
	for _index: int in range(amount):
		dice_pool.append(get_die())
	return dice_pool

func _to_string() -> String:
	return "d%d" % faces
