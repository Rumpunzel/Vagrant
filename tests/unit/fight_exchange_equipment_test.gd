extends GdUnitTestSuite

## Exchanges with weapons, natural weapons and armour, with fixed dice.

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY
const NERVES: CharacterAttribute = Rules.INTELLIGENCE

func test_natural_weapons_always_hit() -> void:
	# Unarmed example 1 against an unarmed monster: its highest breath die is its weapon damage
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 7]), FightTestDice.scores(7))
	var bear: FightSide = FightTestDice.natural(GUTS, [3, 4, 5], FightTestDice.scores(5))
	FightExchange.new(player, bear)
	assert_int(bear.injury_taken).is_equal(2)
	assert_int(player.injury_taken).is_equal(5)

func test_natural_weapons_add_guts_margin() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 3]), FightTestDice.scores(7))
	var bear: FightSide = FightTestDice.natural(GUTS, [2, 4, 5], FightTestDice.scores(7))
	FightExchange.new(player, bear)
	assert_int(player.injury_taken).is_equal(5 + 2)
	assert_int(bear.injury_taken).is_equal(0)

func test_blood_reduces_natural_weapon_damage() -> void:
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.player_dice([1, 1, 2, 2, 7]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3))
	var bear: FightSide = FightTestDice.natural(GUTS, [3, 4, 5], FightTestDice.scores(5))
	FightExchange.new(player, bear)
	assert_int(player.injury_taken).is_equal(5 - 2)
	assert_int(bear.injury_taken).is_equal(3)

func test_natural_weapons_count_even_when_lost() -> void:
	# Guts 3: the 4 and 5 are lost, but the 5 still hits
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 9]), FightTestDice.scores(9))
	var bear: FightSide = FightTestDice.natural(GUTS, [3, 4, 5], FightTestDice.scores(3))
	FightExchange.new(player, bear)
	assert_array(FightTestDice.results(bear.lost_breath_dice)).is_equal([4, 5])
	assert_array(FightTestDice.results(bear.usable_weapon_dice)).is_equal([3, 4, 5])
	assert_int(player.injury_taken).is_equal(5)

func test_weapon_wielded_with_its_attribute() -> void:
	# A Nerves weapon: 6 is fine with Nerves 6 even though Guts is only 3
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 3]), FightTestDice.scores(3, 3, 6), FightTestDice.weapon(Rules.d8, 6))
	player.wield_attribute = NERVES
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 1]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(player.failed_weapon_dice)).is_empty()
	assert_int(player.weapon_damage).is_equal(6)

func test_failed_weapon_die_is_reported() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 3]), FightTestDice.scores(5), FightTestDice.weapon(Rules.d10, 8))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 1]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(player.failed_weapon_dice)).is_equal([8])
	assert_int(player.weapon_damage).is_equal(0)

func test_marked_face_deals_no_damage() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 1, 1, 1]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 4))
	player.marked_faces = [4] as Array[int]
	# The Lurker wins the threat, so the player has no Guts bonus that could hide the missing weapon damage
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([2, 2, 2]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	# Usable (4 <= Guts 7), but crossed out: no weapon damage, and nothing new to mark
	assert_array(FightTestDice.results(player.failed_weapon_dice)).is_empty()
	assert_int(player.weapon_damage).is_equal(0)
	assert_int(lurker.injury_taken).is_equal(0)

func test_armor_blocks_weapon_damage() -> void:
	# Sword 10 against a helmet: blocked, so only the Guts margin hits
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 7]), FightTestDice.scores(12), FightTestDice.weapon(Rules.d10, 10))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5))
	lurker.armor_blocks = [5, 10] as Array[int]
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(player.blocked_weapon_dice)).is_equal([10])
	assert_int(player.weapon_damage).is_equal(0)
	assert_int(player.threat).is_equal(7)
	assert_int(lurker.injury_taken).is_equal(2)

func test_failed_weapon_never_meets_armor() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 3]), FightTestDice.scores(5), FightTestDice.weapon(Rules.d10, 10))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 1]), FightTestDice.scores(5))
	lurker.armor_blocks = [10] as Array[int]
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(player.failed_weapon_dice)).is_equal([10])
	assert_array(FightTestDice.results(player.blocked_weapon_dice)).is_empty()

func test_armor_blocks_natural_weapons_but_not_their_threat() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 9]), FightTestDice.scores(9))
	player.armor_blocks = [6] as Array[int]
	var bear: FightSide = FightTestDice.natural(GUTS, [3, 6, 5], FightTestDice.scores(7))
	FightExchange.new(player, bear)
	assert_array(FightTestDice.results(bear.blocked_weapon_dice)).is_equal([6])
	assert_int(bear.threat).is_equal(6)
	# The 6 is blocked; the next highest natural weapon die (5) still hits
	assert_int(bear.weapon_damage).is_equal(5)

func test_damage_reduction_comes_last() -> void:
	# Lurker weapon 4 + Guts margin 2, player Blood loses: 6, gambeson -1
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.player_dice([1, 1, 1, 1, 3]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	player.damage_reduction = 1
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 2, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 4))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(4 + 2 - 1)

func test_damage_reduction_never_heals() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 1, 1, 5]), FightTestDice.scores(7))
	player.damage_reduction = 3
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 4]), FightTestDice.scores(7))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(0)
