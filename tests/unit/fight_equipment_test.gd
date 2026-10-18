extends GdUnitTestSuite

## Marking equipment in a fight: failing to wield, armour blocks, shields that can't be raised.

const GUTS: CharacterAttribute = Rules.STRENGTH

var _character: Character
var _monster: Monster
var _decision: AdventureFightDecision

func before_test() -> void:
	_character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(_character)
	_character.character_profile = (load("uid://73nsysikxf7j") as CharacterProfile).duplicate(true)  # dorian.tres
	_monster = auto_free(load("uid://kmifqq0ejuri").instantiate())  # monster.tscn
	add_child(_monster)
	_monster.monster_profile = load("uid://d3ytncs0be7oo")  # lurker.tres
	_decision = AdventureFightDecision.new()

func test_failing_to_wield_marks_then_ruins() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 9)
	assert_bool(sword.is_marked(9)).is_true()
	assert_bool(sword.ruined).is_false()
	assert_str(fight.get_exchange_summary()).contains("A 9 is marked on your Sword.")
	_apply_armed(fight, sword, 9)
	assert_bool(sword.ruined).is_true()
	assert_str(fight.get_exchange_summary()).contains("Your Sword is ruined.")

func test_wielded_weapon_is_not_marked() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 4)
	assert_array(sword.marked_faces).is_empty()

func test_blocked_die_marks_weapon_and_one_armor_piece() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	_monster.armor = Armor.carry([ArmorProfile.create("Helmet", [5, 10] as Array[int]), ArmorProfile.create("Coif", [10] as Array[int])] as Array[ArmorProfile])
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 10, [10] as Array[int], 12)
	assert_bool(sword.is_marked(10)).is_true()
	var marked_pieces: Array[Armor] = []
	marked_pieces.assign(_monster.armor.filter(func(piece: Armor) -> bool: return piece.is_marked(10)))
	assert_int(marked_pieces.size()).is_equal(1)
	assert_str(fight.get_exchange_summary()).contains("blocks the 10.")
	assert_str(fight.get_exchange_summary()).contains("A 10 is marked on your Sword.")

func test_blocking_a_marked_result_ruins_the_armor() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	_monster.armor = Armor.carry([ArmorProfile.create("Helmet", [5, 10] as Array[int])] as Array[ArmorProfile])
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 5, [5, 10] as Array[int], 12)
	_apply_armed(fight, sword, 5, [5, 10] as Array[int], 12)
	assert_bool(_monster.armor[0].ruined).is_true()
	assert_bool(sword.ruined).is_true()
	assert_str(fight.get_exchange_summary()).contains("The Lurker's Helmet is ruined.")

func test_natural_weapons_only_mark_the_armor() -> void:
	_character.armor = Armor.carry([ArmorProfile.create("Helmet", [5, 10] as Array[int])] as Array[ArmorProfile])
	var fight: Fight = Fight.new(_decision, _character, _monster)
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	player.armor_blocks = [5, 10] as Array[int]
	var bear_dice: Array[Die] = FightTestDice.dice([Rules.d8, Rules.d8], [5, 1])
	var bear: FightSide = FightSide.new(GUTS, bear_dice, FightTestDice.scores(7), bear_dice)
	bear.has_natural_weapons = true
	fight.apply_exchange(FightExchange.new(player, bear), player.lost_breath_dice)
	assert_bool(_character.armor[0].is_marked(5)).is_true()

func test_shield_that_cannot_be_raised_gets_marked() -> void:
	var buckler: Shield = Shield.create(ShieldProfile.create("Buckler", Rules.d6))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(4))
	player.shield_dice = FightTestDice.dice([Rules.d6], [6])
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8, Rules.d8], [1, 1]), FightTestDice.scores(5))
	fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, null, null, buckler)
	assert_bool(buckler.is_marked(6)).is_true()
	assert_str(fight.get_exchange_summary()).contains("You fail to raise your shield.")
	assert_str(fight.get_exchange_summary()).contains("A 6 is marked on your Buckler.")

## One exchange where the player swings [param sword] and rolls [param result]
func _apply_armed(fight: Fight, sword: Weapon, result: int, opponent_armor_blocks: Array[int] = [], guts: int = 7) -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(guts), FightTestDice.dice([sword.get_die_type()], [result]))
	player.marked_faces = sword.marked_faces.duplicate()
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8, Rules.d8], [1, 1]), FightTestDice.scores(5))
	opponent.armor_blocks = opponent_armor_blocks
	fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, sword)
