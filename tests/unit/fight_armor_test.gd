extends GdUnitTestSuite

## Armour taking blocked blows: which piece, marking or ruining it, and when the player gets to decide.

const GUTS: CharacterAttribute = Rules.STRENGTH

var _character: Character
var _monster: Monster
var _fight: Fight

func before_test() -> void:
	_character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(_character)
	_character.character_profile = TestCharacters.adventurer()
	_monster = auto_free(load("uid://kmifqq0ejuri").instantiate())  # monster.tscn
	add_child(_monster)
	_monster.monster_profile = TestMonsters.cutthroat()
	_fight = Fight.new(AdventureFightDecision.new(), _character, _monster)

func test_only_pieces_with_the_fitting_result_unmarked_are_options() -> void:
	var helmet: Armor = _piece("Helmet", [5, 10])
	var coif: Armor = _piece("Coif", [10], [10])
	var options: Array[ArmorPick] = ArmorPick.get_options([helmet, coif] as Array[Armor], 10)
	assert_int(options.size()).is_equal(1)
	assert_object(options[0].piece).is_same(helmet)
	assert_bool(options[0].ruin).is_false()

func test_with_every_fitting_result_marked_mark_higher_or_ruin() -> void:
	var helmet: Armor = _piece("Helmet", [5, 10], [5])
	var options: Array[ArmorPick] = ArmorPick.get_options([helmet] as Array[Armor], 5)
	assert_array(options.map(func(option: ArmorPick) -> bool: return option.ruin)).is_equal([false, true])

func test_without_a_higher_result_the_piece_can_only_be_ruined() -> void:
	var coif: Armor = _piece("Coif", [10], [10])
	var options: Array[ArmorPick] = ArmorPick.get_options([coif] as Array[Armor], 10)
	assert_int(options.size()).is_equal(1)
	assert_bool(options[0].ruin).is_true()

func test_default_wears_down_the_piece_with_most_unmarked_results() -> void:
	var helmet: Armor = _piece("Helmet", [5, 10])
	var coif: Armor = _piece("Coif", [10])
	assert_object(SparingArmorTactic.new().pick(ArmorPick.get_options([coif, helmet] as Array[Armor], 10)).piece).is_same(helmet)

func test_default_marks_higher_rather_than_ruin() -> void:
	var helmet: Armor = _piece("Helmet", [5, 10], [5])
	assert_bool(SparingArmorTactic.new().pick(ArmorPick.get_options([helmet] as Array[Armor], 5)).ruin).is_false()

func test_the_players_pick_takes_the_blow() -> void:
	var helmet: Armor = _piece("Helmet", [5, 10])
	var coif: Armor = _piece("Coif", [10])
	_character.armor = [helmet, coif] as Array[Armor]
	_start_exchange_with_the_monster_hitting(10)
	_advance_to_armor_choice()
	var step: ArmorChoiceStep = _fight.get_current_step()
	var blocked_die: Die = step.get_undecided_die(_fight)
	_fight.armor_picks[blocked_die] = ArmorPick.new(coif)
	_finish_exchange()
	assert_array(coif.marked_faces).is_equal([10])
	assert_array(helmet.marked_faces).is_empty()

func test_ruining_a_piece_still_blocks() -> void:
	var coif: Armor = _piece("Coif", [10], [10])
	_character.armor = [coif] as Array[Armor]
	_start_exchange_with_the_monster_hitting(10)
	_finish_exchange()
	assert_bool(coif.ruined).is_true()
	assert_array(_fight.get_last_exchange().second.blocked_weapon_dice).is_not_empty()
	assert_str(_fight.get_exchange_summary()).contains("Your Coif blocks the 10 and is ruined.")

func test_no_decision_with_a_single_option() -> void:
	_character.armor = [_piece("Helmet", [5, 10])] as Array[Armor]
	_start_exchange_with_the_monster_hitting(10)
	var steps: Array[Script] = []
	while _fight.is_exchange_pending():
		steps.append(_fight.get_current_step().get_script())
		_fight.advance()
	assert_array(steps).not_contains([ArmorChoiceStep])

func _piece(piece_name: String, blocked_results: Array[int], marked_results: Array[int] = []) -> Armor:
	return Armor.create(ArmorProfile.create(piece_name, blocked_results), marked_results)

## The Cutthroat strikes with a d10 of [param result] and wins the threat; the player is unarmed
func _start_exchange_with_the_monster_hitting(result: int) -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	player.armor_blocks = Armor.get_blocked_results(_character.armor)
	var monster: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [3]), FightTestDice.scores(12), FightTestDice.weapon(Rules.d10, result))
	_fight.start_exchange(FightExchange.new(player, monster), player.lost_breath_dice, null, Weapon.create(WeaponProfile.create("Club", Rules.d10)))

func _advance_to_armor_choice() -> void:
	while not _fight.get_current_step() is ArmorChoiceStep: _fight.advance()

func _finish_exchange() -> void:
	while _fight.is_exchange_pending(): _fight.advance()
	_fight.end_exchange()
