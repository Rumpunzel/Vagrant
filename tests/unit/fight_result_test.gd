extends GdUnitTestSuite

## FightRequest -> FightResult wiring with real resources; dice are random, so invariants are checked over many rolls.

const ROLLS: int = 50

var _character: Character
var _monster: Monster

func before_test() -> void:
	var profile: CharacterProfile = TestCharacters.adventurer()
	profile.weapons = [WeaponProfile.create("Sword", Rules.d10)] as Array[WeaponProfile]
	_character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(_character)
	_character.character_profile = profile
	_monster = auto_free(load("uid://kmifqq0ejuri").instantiate())  # monster.tscn
	var cutthroat: MonsterProfile = TestMonsters.cutthroat()
	cutthroat.weapons = [WeaponProfile.create("Knife", Rules.d8), WeaponProfile.create("Club", Rules.d6)] as Array[WeaponProfile]
	add_child(_monster)
	_monster.monster_profile = cutthroat

func test_builds_both_sides() -> void:
	for _roll: int in ROLLS:
		var request: FightRequest = _create_request()
		var result: FightResult = request.roll()
		var player: FightSide = result.get_player_side()
		var opponent: FightSide = result.get_opponent_side()
		assert_array(player.breath_dice).is_equal(result.dice)
		assert_int(player.breath_dice.size()).is_equal(_selected_count(request))
		assert_int(player.weapon_dice.size()).is_equal(1)
		assert_int(opponent.breath_dice.size()).is_equal(3)
		assert_int(opponent.weapon_dice.size()).is_equal(1)
		assert_object(opponent.stance).is_same(Rules.STRENGTH)
		for attribute: CharacterAttribute in Rules.ATTRIBUTES:
			assert_int(player.scores[attribute]).is_equal(_character.get_attribute_score(attribute).get_score())
			assert_int(opponent.scores[attribute]).is_equal(_monster.get_score(attribute))

func test_nerves_attack_reaches_the_opponent_side() -> void:
	_monster.monster_profile = TestMonsters.unnerver(Rules.AGILITY)
	var opponent: FightSide = _create_request().roll().get_opponent_side()
	assert_object(opponent.stance).is_same(Rules.INTELLIGENCE)
	assert_object(opponent.nerves_target).is_same(Rules.AGILITY)

func test_extra_weapon_dice_ability_rolls_more_of_the_weapon() -> void:
	var extra: ExtraWeaponDiceAbility = ExtraWeaponDiceAbility.new()
	_character.character_profile.origins[0].abilities = [extra] as Array[Ability]
	var player: FightSide = _create_request().roll().get_player_side()
	assert_array(player.abilities).contains_same_exactly(extra)
	assert_int(player.weapon_dice.size()).is_equal(2)
	for die: Die in player.weapon_dice: assert_object(die.die_type).is_same(Rules.d10)
	# Unarmed there is no weapon to roll more of
	var request: FightRequest = _create_request()
	request.selected_weapon = null
	assert_array(request.roll().get_player_side().weapon_dice).is_empty()

func test_outcome_and_margin_follow_threat() -> void:
	for _roll: int in ROLLS:
		var result: FightResult = _create_request().roll()
		var difference: int = result.get_player_side().threat - result.get_opponent_side().threat
		assert_int(result.get_margin()).is_equal(absi(difference))
		var expected: DiceRequestResult.Outcome = DiceRequestResult.Outcome.DRAW
		if difference > 0: expected = DiceRequestResult.Outcome.SUCCESS
		elif difference < 0: expected = DiceRequestResult.Outcome.FAILURE
		assert_int(result.get_outcome()).is_equal(expected)

func test_lost_breath_dice_come_from_exchange() -> void:
	for _roll: int in ROLLS:
		var result: FightResult = _create_request().roll()
		var lost: Array[Die] = result.get_lost_breath_dice()
		for die: Die in lost: assert_bool(result.get_player_side().lost_breath_dice.has(die)).is_true()

func test_fleeing_rolls_blood() -> void:
	var request: FightRequest = _create_request()
	request.fleeing = true
	var result: FightResult = request.roll()
	assert_object(result.get_player_side().stance).is_same(Rules.AGILITY)

func test_character_loses_breath_dice() -> void:
	var request: FightRequest = _create_request()
	var before: int = _total(_character.breath_dice)
	var result: FightResult = request.roll()
	_character.parse_dice_result(result)
	assert_int(_total(_character.breath_dice)).is_equal(before - result.get_lost_breath_dice().size())

func test_unarmed_monster_fights_with_its_breath_dice() -> void:
	_monster.monster_profile.weapons = [] as Array[WeaponProfile]
	assert_bool(_monster.has_natural_weapons()).is_true()
	for _roll: int in ROLLS:
		var opponent: FightSide = _create_request().roll().get_opponent_side()
		assert_bool(opponent.has_natural_weapons).is_true()
		assert_array(opponent.weapon_dice).is_equal(opponent.breath_dice)
		assert_int(opponent.weapon_damage).is_equal(opponent.threat)

func test_armed_monster_uses_its_weapon() -> void:
	assert_bool(_monster.has_natural_weapons()).is_false()
	var opponent: FightSide = _create_request().roll().get_opponent_side()
	assert_bool(opponent.has_natural_weapons).is_false()
	assert_int(opponent.weapon_dice.size()).is_equal(1)
	assert_object(opponent.weapon_dice[0].die_type).is_same(Rules.d8)

func test_armor_reaches_both_sides() -> void:
	_character.armor = Armor.carry([ArmorProfile.create("Gambeson", [] as Array[int], 1), ArmorProfile.create("Helmet", [5, 10] as Array[int])] as Array[ArmorProfile])
	_monster.armor = Armor.carry([ArmorProfile.create("Plate", [2, 4] as Array[int])] as Array[ArmorProfile])
	var result: FightResult = _create_request().roll()
	assert_array(result.get_player_side().armor_blocks).is_equal([5, 10])
	assert_int(result.get_player_side().damage_reduction).is_equal(1)
	assert_array(result.get_opponent_side().armor_blocks).is_equal([2, 4])
	assert_int(result.get_opponent_side().damage_reduction).is_equal(0)

func test_shields_are_rolled_for_both_sides() -> void:
	_character.shields = Shield.carry([ShieldProfile.create("Buckler", Rules.d6), ShieldProfile.create("Pavise", Rules.d12)] as Array[ShieldProfile])
	_character.shields[0].ruined = true
	_monster.shields = Shield.carry([ShieldProfile.create("Round Shield", Rules.d8)] as Array[ShieldProfile])
	var result: FightResult = _create_request().roll()
	assert_object(result.player_shield).is_same(_character.shields[1])
	assert_object(result.get_player_side().shield_dice[0].die_type).is_same(Rules.d12)
	assert_object(result.opponent_shield).is_same(_monster.shields[0])
	assert_object(result.get_opponent_side().shield_dice[0].die_type).is_same(Rules.d8)

func test_stance_descriptions_come_from_fight_stances() -> void:
	var request: FightRequest = _create_request()
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		assert_str(attribute.fight_stance.description).is_not_empty()
		assert_str(request.get_stance_description(attribute)).is_equal(attribute.fight_stance.description)
	# A fight decision can word a stance its own way
	request.get_source().stance_descriptions[Rules.AGILITY] = "Dodge the knife!"
	assert_str(request.get_stance_description(Rules.AGILITY)).is_equal("Dodge the knife!")

func test_request_picks_first_usable_weapon() -> void:
	var sword: Weapon = _character.weapons[0]
	assert_object(_create_request().selected_weapon).is_same(sword)
	sword.ruined = true
	assert_object(_create_request().selected_weapon).is_null()

func test_fighting_unarmed_by_choice() -> void:
	var request: FightRequest = _create_request()
	request.attribute = Rules.AGILITY
	request.selected_weapon = null
	assert_bool(request.has_stance_choice()).is_false()
	assert_object(request.attribute).is_same(Rules.STRENGTH)
	var player: FightSide = request.roll().get_player_side()
	assert_bool(player.is_armed()).is_false()
	assert_object(player.stance).is_same(Rules.STRENGTH)

func test_player_side_uses_picked_weapon() -> void:
	var sword: Weapon = _character.weapons[0]
	sword.marked_faces = [3] as Array[int]
	var player: FightSide = _create_request().roll().get_player_side()
	assert_int(player.weapon_dice.size()).is_equal(1)
	assert_object(player.weapon_dice[0].die_type).is_same(Rules.d10)
	assert_object(player.wield_attribute).is_same(Rules.STRENGTH)
	assert_array(player.marked_faces).is_equal([3])

func test_armed_monster_uses_first_usable_weapon() -> void:
	var result: FightResult = _create_request().roll()
	assert_object(result.opponent_weapon).is_same(_monster.weapons[0])
	_monster.weapons[0].ruined = true
	result = _create_request().roll()
	assert_object(result.opponent_weapon).is_same(_monster.weapons[1])
	assert_object(result.get_opponent_side().weapon_dice[0].die_type).is_same(Rules.d6)
	# With every weapon ruined it fights unarmed, not with natural weapons
	_monster.weapons[1].ruined = true
	result = _create_request().roll()
	assert_object(result.opponent_weapon).is_null()
	assert_bool(result.get_opponent_side().is_armed()).is_false()
	assert_bool(result.get_opponent_side().has_natural_weapons).is_false()

func _create_request() -> FightRequest:
	var request: FightRequest = FightRequest.new(_character, AdventureFightDecision.new())
	request.opponent = _monster
	request.attribute = Rules.STRENGTH
	# Roll every breath die so losses are likely
	request.selected_breath_dice = _character.breath_dice.duplicate()
	return request

func _selected_count(request: FightRequest) -> int:
	return _total(request.selected_breath_dice)

func _total(dice: Dictionary[DieType, int]) -> int:
	var total: int = 0
	for amount: int in dice.values(): total += amount
	return total
