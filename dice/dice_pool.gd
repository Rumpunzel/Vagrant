class_name DicePool

signal dice_pool_changed(new_pool: DicePool)

var dice: Array[DiceRoller.Dice] = [ ]

func _init(new_dice: Array[DiceRoller.Dice] = [ ]) -> void:
	self.dice = new_dice
	dice_pool_changed.emit(self)

static func get_2d6() -> DicePool:
	return DicePool.new([DiceRoller.Dice.d6, DiceRoller.Dice.d6])

static func get_full_set() -> DicePool:
	return DicePool.new([
		DiceRoller.Dice.d4,
		DiceRoller.Dice.d6,
		DiceRoller.Dice.d8,
		DiceRoller.Dice.d10,
		DiceRoller.Dice.d12,
	])

func add_die(new_die: DiceRoller.Dice) -> void:
	dice.append(new_die)
	dice_pool_changed.emit(self)

func add_dice(new_dice: Array[DiceRoller.Dice]) -> void:
	dice += new_dice
	dice_pool_changed.emit(self)

func remove_die(die: DiceRoller.Dice) -> void:
	dice.erase(die)
	dice_pool_changed.emit(self)

func get_dice_count(die_to_count: DiceRoller.Dice) -> int:
	var count := 0
	for die: DiceRoller.Dice in dice:
		if die == die_to_count: count += 1
	return count

func _to_string() -> String:
	var dice_map := { }
	for die: DiceRoller.Dice in dice:
		dice_map[die] = dice_map.get(dice_map, 0) + 1
	if dice_map.is_empty(): return "-"
	var string := ""
	for die: DiceRoller.Dice in dice_map.keys():
		string += "%dd%d, " % [dice_map[die], die]
	return string.trim_suffix(", ")
