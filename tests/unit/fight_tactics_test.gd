extends GdUnitTestSuite

## Tactics: how a side decides on its weapon, shield and armour when nobody asks the player.

const GUTS: CharacterAttribute = Rules.STRENGTH

class LastOptionArmorTactic extends ArmorTactic:
	func pick(options: Array[ArmorPick]) -> ArmorPick: return options.back()

var _character: Character
var _monster: Monster

func before_test() -> void:
	_character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(_character)
	_character.character_profile = TestCharacters.adventurer()
	_monster = auto_free(load("uid://kmifqq0ejuri").instantiate())  # monster.tscn
	add_child(_monster)
	_monster.monster_profile = TestMonsters.cutthroat()

func test_weapon_tactic_never_forces_by_default() -> void:
	var side: FightSide = _armed(9, null)
	FightExchange.new(side, _unarmed())
	assert_array(side.usable_weapon_dice).is_empty()

func test_weapon_tactic_forces_up_to_its_max_overshoot() -> void:
	var side: FightSide = _armed(9, _forcing_weapon(2))
	FightExchange.new(side, _unarmed())
	assert_int(side.weapon_damage).is_equal(9)
	assert_int(side.weapon_strain).is_equal(FightSide.Strain.OVERREACH)
	assert_int(side.threat).is_equal(-1)

func test_weapon_tactic_holds_back_beyond_its_max_overshoot() -> void:
	var side: FightSide = _armed(9, _forcing_weapon(1))
	FightExchange.new(side, _unarmed())
	assert_array(side.usable_weapon_dice).is_empty()

func test_weapon_tactic_forces_marked_faces_only_if_set() -> void:
	var side: FightSide = _armed(5, _forcing_weapon(0))
	side.marked_faces = [5] as Array[int]
	FightExchange.new(side, _unarmed())
	assert_array(side.usable_weapon_dice).is_empty()
	var tactic: ForcingWeaponTactic = _forcing_weapon(0)
	tactic.force_marked_faces = true
	var forcing: FightSide = _armed(5, tactic)
	forcing.marked_faces = [5] as Array[int]
	FightExchange.new(forcing, _unarmed())
	assert_int(forcing.weapon_strain).is_equal(FightSide.Strain.MARKED_FACE)

func test_shield_tactic_never_forces_by_default() -> void:
	var side: FightSide = _shielded(8, null)
	FightExchange.new(side, _hitting())
	assert_bool(side.raises_shield).is_false()

func test_shield_tactic_forces_up_to_its_max_overshoot() -> void:
	var tactic: ForcingShieldTactic = ForcingShieldTactic.new()
	tactic.max_overshoot = 1
	var side: FightSide = _shielded(8, tactic)
	FightExchange.new(side, _hitting())
	assert_bool(side.raises_shield).is_true()
	assert_int(side.shield_overshoot).is_equal(1)
	assert_int(side.threat).is_equal(0)

func test_armor_step_follows_the_monsters_armor_tactic() -> void:
	var helmet: Armor = Armor.create(ArmorProfile.create("Helmet", [5, 10] as Array[int]))
	var coif: Armor = Armor.create(ArmorProfile.create("Coif", [10] as Array[int]))
	_monster.armor = [helmet, coif] as Array[Armor]
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(12), FightTestDice.weapon(Rules.d10, 10))
	var opponent: FightSide = _unarmed()
	opponent.armor_blocks = [5, 10] as Array[int]
	opponent.armor_tactic = LastOptionArmorTactic.new()
	var fight: Fight = Fight.new(AdventureFightDecision.new(), _character, _monster, _character)
	player.weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	fight.apply_exchange(FightExchange.new(player, opponent))
	# The sparing default would have worn down the Helmet
	assert_array(coif.marked_faces).is_equal([10])
	assert_array(helmet.marked_faces).is_empty()

func test_monster_tactics_reach_its_side() -> void:
	var profile: MonsterProfile = TestMonsters.cutthroat()
	profile.weapon_tactic = _forcing_weapon(12)
	profile.shield_tactic = ForcingShieldTactic.new()
	profile.armor_tactic = LastOptionArmorTactic.new()
	_monster.monster_profile = profile
	var request: FightRequest = FightRequest.new(_character, AdventureFightDecision.new())
	request.opponent = _monster
	request.attribute = GUTS
	var opponent: FightSide = request.roll().get_opponent_side()
	assert_object(opponent.weapon_tactic).is_same(profile.weapon_tactic)
	assert_object(opponent.shield_tactic).is_same(profile.shield_tactic)
	assert_object(opponent.armor_tactic).is_same(profile.armor_tactic)

## Guts 7 with a d10 weapon die of [param result]; its breath die can't win the threat
func _armed(result: int, tactic: WeaponTactic) -> FightSide:
	var side: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, result))
	side.weapon_tactic = tactic
	return side

## Guts 7 with a d8 shield die of [param result], facing a blow
func _shielded(result: int, tactic: ShieldTactic) -> FightSide:
	var side: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	side.shield_dice = FightTestDice.dice([Rules.d8], [result])
	side.shield_tactic = tactic
	return side

func _forcing_weapon(max_overshoot: int) -> ForcingWeaponTactic:
	var tactic: ForcingWeaponTactic = ForcingWeaponTactic.new()
	tactic.max_overshoot = max_overshoot
	return tactic

func _unarmed() -> FightSide:
	return FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7))

## Wins the threat by 4: a blow of 4
func _hitting() -> FightSide:
	return FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [5]), FightTestDice.scores(7))
