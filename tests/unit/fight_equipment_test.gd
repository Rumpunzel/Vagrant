extends GdUnitTestSuite

## Marking equipment in a fight: failing to wield, armour blocks, shields that can't be raised.

const GUTS: CharacterAttribute = Rules.STRENGTH

var _character: Character
var _monster: Monster
var _decision: AdventureFightDecision
## What the last [method _raise] told
var _fight_text: String = ""

func before_test() -> void:
	_character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(_character)
	_character.character_profile = TestCharacters.adventurer()
	_monster = auto_free(load("uid://kmifqq0ejuri").instantiate())  # monster.tscn
	add_child(_monster)
	_monster.monster_profile = TestMonsters.cutthroat()
	_decision = AdventureFightDecision.new()

func test_a_die_beyond_guts_is_held_back_unless_forced() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 9)
	assert_array(sword.marked_faces).is_empty()
	assert_str(fight.get_exchange_summary()).contains("You hold back your Sword.")

func test_forcing_beyond_guts_marks_every_face() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 9, [], 7, true)
	assert_array(sword.marked_faces).is_equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	assert_bool(sword.ruined).is_false()
	assert_str(fight.get_exchange_summary()).contains("You force your Sword beyond your strength: every face is marked.")

func test_forcing_a_marked_face_marks_the_next_higher_one() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10), [4] as Array[int])
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, sword, 4, [], 7, true)
	assert_array(sword.marked_faces).is_equal([4, 5])
	assert_str(fight.get_exchange_summary()).contains("You force the marked 4. A 5 is marked on your Sword.")

func test_choosing_a_weapon_die_resolves_the_exchange_again() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7), FightTestDice.dice([Rules.d10], [9]))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8, Rules.d8], [1, 1]), FightTestDice.scores(5))
	fight.start_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, sword)
	assert_int(fight.get_last_exchange().first.weapon_damage).is_equal(0)
	fight.resolve_player_choice(func(side: FightSide) -> void: side.chosen_weapon_die = player.weapon_dice[0])
	assert_int(fight.get_last_exchange().first.weapon_damage).is_equal(9)
	assert_object(fight.get_last_exchange().first.breath_dice).is_same(player.breath_dice)

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
	# Without a pick, the piece with the most unmarked results takes it
	assert_bool(_monster.armor[0].is_marked(10)).is_true()
	assert_bool(_monster.armor[1].is_marked(10)).is_false()
	assert_str(fight.get_exchange_summary()).contains("blocks the 10.")
	assert_str(fight.get_exchange_summary()).contains("A 10 is marked on your Sword.")

func test_blocking_a_marked_result_marks_the_next_higher_one() -> void:
	_monster.armor = Armor.carry([ArmorProfile.create("Helmet", [5, 10] as Array[int])] as Array[ArmorProfile])
	var fight: Fight = Fight.new(_decision, _character, _monster)
	# A fresh sword each time, so its own marks don't keep it from striking
	_apply_armed(fight, Weapon.create(WeaponProfile.create("Sword", Rules.d10)), 5, [5, 10] as Array[int], 12)
	assert_array(_monster.armor[0].marked_faces).is_equal([5])
	_apply_armed(fight, Weapon.create(WeaponProfile.create("Sword", Rules.d10)), 5, [5, 10] as Array[int], 12)
	assert_array(_monster.armor[0].marked_faces).is_equal([5, 10])
	_apply_armed(fight, Weapon.create(WeaponProfile.create("Sword", Rules.d10)), 5, [5, 10] as Array[int], 12)
	# Nothing higher than the 10 is left: the Helmet still blocks, and is ruined
	assert_bool(_monster.armor[0].ruined).is_true()
	assert_str(fight.get_exchange_summary()).contains("The Cutthroat's Helmet blocks the 5 and is ruined.")

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

func test_summary_has_one_paragraph_per_step_and_side() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var knife: Weapon = Weapon.create(WeaponProfile.create("Knife", Rules.d8))
	_monster.armor = Armor.carry([ArmorProfile.create("Gambeson", [] as Array[int], 1)] as Array[ArmorProfile])
	var fight: Fight = Fight.new(_decision, _character, _monster)
	# The cutthroat's Nerves (6) beat the player's Guts (4) by 2; its knife (7) would need forcing beyond its Guts 5
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3))
	var opponent: FightSide = FightSide.new(Rules.INTELLIGENCE, FightTestDice.dice([Rules.d8, Rules.d8], [6, 2]), FightTestDice.scores(5, 5, 7), FightTestDice.weapon(Rules.d8, 7), false, GUTS)
	opponent.damage_reduction = 1
	fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, sword, knife)
	var guts: String = Fight.describe_attribute(GUTS)
	var paragraphs: PackedStringArray = fight.get_exchange_summary().trim_prefix("[p]").trim_suffix("[/p]").split("[/p][p]")
	# Every step and side tells its own paragraph; their order is authored in exchange_steps.tres
	assert_array(Array(paragraphs)).contains_exactly_in_any_order([
		"You threaten with %s (4) and your Sword (3)." % guts,
		"The Cutthroat threatens with %s (6) and its Knife (7)." % Fight.describe_attribute(Rules.INTELLIGENCE),
		"The Cutthroat unnerves you (−2 %s)." % guts,
		"The Cutthroat holds back its Knife.",
		"The Cutthroat's armour takes 1 off your blow.",
	])

func test_raising_a_shield_marks_its_face() -> void:
	var buckler: Shield = Shield.create(ShieldProfile.create("Buckler", Rules.d6))
	_raise(buckler, 3)
	assert_array(buckler.marked_faces).is_equal([3])
	assert_str(_fight_text).contains("You raise your Buckler: 3 off the Cutthroat's blow. A 3 is marked on your Buckler.")

func test_raising_on_a_marked_face_marks_the_next_higher_one() -> void:
	var buckler: Shield = Shield.create(ShieldProfile.create("Buckler", Rules.d6), [3] as Array[int])
	_raise(buckler, 3)
	assert_array(buckler.marked_faces).is_equal([3, 4])

func test_forcing_a_shield_up_ruins_it() -> void:
	var buckler: Shield = Shield.create(ShieldProfile.create("Buckler", Rules.d6))
	_raise(buckler, 6, 5)
	assert_bool(buckler.ruined).is_true()
	assert_str(_fight_text).contains("Your Buckler is ruined.")

func test_summary_without_shields_has_no_shield_paragraph() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply_armed(fight, Weapon.create(WeaponProfile.create("Sword", Rules.d10)), 4)
	assert_str(fight.get_exchange_summary()).not_contains("shield")
	assert_str(fight.get_exchange_summary()).not_contains("Now you")

func test_summary_lists_every_weapon_die() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	var fight: Fight = Fight.new(_decision, _character, _monster)
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(7), FightTestDice.dice([Rules.d10, Rules.d10], [3, 6]))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [2]), FightTestDice.scores(5))
	fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, sword)
	assert_str(fight.get_exchange_summary()).contains("and your Sword (3, 6)")

## One exchange where the player swings [param sword] and rolls [param result]
func _apply_armed(fight: Fight, sword: Weapon, result: int, opponent_armor_blocks: Array[int] = [], guts: int = 7, force: bool = false) -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(guts), FightTestDice.dice([sword.get_die_type()], [result]))
	player.marked_faces = sword.marked_faces.duplicate()
	if force: player.chosen_weapon_die = player.weapon_dice[0]
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8, Rules.d8], [1, 1]), FightTestDice.scores(5))
	opponent.armor_blocks = opponent_armor_blocks
	fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, sword)

## The Cutthroat's unarmed vantage of 4 comes at the player, who raises [param shield] on [param result] (forced if beyond [param guts])
func _raise(shield: Shield, result: int, guts: int = 7) -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(guts))
	player.shield_dice = FightTestDice.dice([shield.get_die_type()], [result])
	player.shield_marked_faces = shield.marked_faces.duplicate()
	player.shield_use = FightSide.ShieldUse.RAISE
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [5]), FightTestDice.scores(5))
	fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice, null, null, shield)
	_fight_text = fight.get_exchange_summary()

