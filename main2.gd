extends Node

@onready var _player: Character = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player.attributes.roll_stats()
	print(_player.attributes)
	print()
	print("hit_dice: %s" % [_player.hit_dice])
	var blood_save := _player.roll_blood_save()
	print("blood_save: %d" % blood_save)
	print("hit_dice: %s" % [_player.hit_dice])
