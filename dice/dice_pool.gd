class_name DicePool

signal dice_pool_changed(new_pool: DicePool)

enum Dice {
	d4 = 4,
	d6 = 6,
	d8 = 8,
	d10 = 10,
	d12 = 12,
	d20 = 20,
}

var _dice: Array[Dice] = [ ]

func _init(new_dice: Array[Dice]) -> void:
	_dice = new_dice
	dice_pool_changed.emit(self)

static func get_2d6() -> DicePool:
	return DicePool.new([Dice.d6, Dice.d6])

static func get_full_set() -> DicePool:
	return DicePool.new([Dice.d4, Dice.d6, Dice.d8, Dice.d10, Dice.d12])

func add_die(die: Dice) -> void:
	_dice.append(die)
	dice_pool_changed.emit(self)

func add_dice(dice: Array[Dice]) -> void:
	_dice += dice
	dice_pool_changed.emit(self)

func remove_die(die: Dice) -> void:
	_dice.erase(die)
	dice_pool_changed.emit(self)

func roll_sum() -> int:
	var sum := 0
	for die: Dice in _dice:
		sum += randi_range(1, die)
	return sum

func roll_save(attribute_score: int) -> int:
	var highest := 0
	var exhausted_dice := [ ]
	for die: Dice in _dice:
		var result := randi_range(1, die)
		if result > highest: highest = result
		var exhausted := result > attribute_score
		if exhausted: exhausted_dice.append(die)
		print("%s came up: %d%s" % [die, result, " -> die is lost!" if exhausted else ""])
	for die: Dice in exhausted_dice:
		remove_die(die)
	return highest

func get_dice_count(die_to_count: Dice) -> int:
	var count := 0
	for die: Dice in _dice:
		if die == die_to_count: count += 1
	return count

func _to_string() -> String:
	var dice_map := { }
	for die: Dice in _dice:
		dice_map[die] = dice_map.get(dice_map, 0) + 1
	if dice_map.is_empty(): return "-"
	var string := ""
	for die: Dice in dice_map.keys():
		string += "%dd%d, " % [dice_map[die], die]
	return string.trim_suffix(", ")
