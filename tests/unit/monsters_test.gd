extends GdUnitTestSuite

## Monsters: spawning and identity by spawning page, profile and index; runtime state.

const LURKER: String = "uid://d3ytncs0be7oo"  # lurker.tres
const GOBLIN: String = "uid://bgt5q8uo31yh0"  # goblin.tres

var _monsters: Monsters
var _page: AdventurePage
var _other_page: AdventurePage

func before_test() -> void:
	_monsters = auto_free(Monsters.new())
	add_child(_monsters)
	_page = AdventurePage.new()
	_other_page = AdventurePage.new()

func test_same_key_returns_same_monster() -> void:
	var lurker: Monster = _monsters.get_monster(_page, load(LURKER))
	assert_object(_monsters.get_monster(_page, load(LURKER))).is_same(lurker)
	assert_object(lurker.spawned_from).is_same(_page)
	assert_object(lurker.get_parent()).is_same(_monsters)

func test_index_page_and_profile_tell_monsters_apart() -> void:
	var lurker: Monster = _monsters.get_monster(_page, load(LURKER))
	var second_lurker: Monster = _monsters.get_monster(_page, load(LURKER), 1)
	var goblin: Monster = _monsters.get_monster(_page, load(GOBLIN))
	var other_lurker: Monster = _monsters.get_monster(_other_page, load(LURKER))
	# Identity, not equality: two fresh Lurkers have equal properties
	for other: Monster in [second_lurker, goblin, other_lurker]: assert_object(other).is_not_same(lurker)
	assert_int(_monsters.get_child_count()).is_equal(4)
	assert_int(_monsters.get_all_monsters_of_type(load(LURKER)).size()).is_equal(3)
	assert_array(_monsters.get_all_monsters_of_type(MonsterProfile.new())).is_empty()

func test_injuries_persist_but_breath_recovers() -> void:
	var lurker: Monster = _monsters.get_monster(_page, load(LURKER))
	var guts: int = lurker.get_score(Rules.STRENGTH)
	lurker.suffer_injury(Injury.new(2))
	lurker.lose_breath_dice(lurker.get_breath_dice_pool())
	assert_bool(lurker.is_out_of_breath()).is_true()
	assert_int(lurker.get_injury_total()).is_equal(2)
	lurker.recover_breath()
	var again: Monster = _monsters.get_monster(_page, load(LURKER))
	assert_bool(again.is_out_of_breath()).is_false()
	assert_int(again.get_breath_dice_count()).is_equal(3)
	assert_int(again.get_score(Rules.STRENGTH)).is_equal(guts - 2)

func test_weapon_dice_come_from_profile() -> void:
	var lurker: Monster = _monsters.get_monster(_page, load(LURKER))
	var weapons: Array[WeaponDie] = lurker.get_weapon_dice()
	assert_int(weapons.size()).is_equal(lurker.monster_profile.weapon_dice.size())
	for weapon: WeaponDie in weapons: assert_bool(weapon.is_alive()).is_true()

func test_weapon_die_exhausts_above_score() -> void:
	var weapon: WeaponDie = WeaponDie.new(Rules.d8)
	var result: int = weapon.roll_damage(0, false)
	assert_int(result).is_between(1, 8)
	assert_int(weapon.state).is_equal(WeaponDie.State.EXHAUSTED)
	assert_bool(weapon.is_alive()).is_false()
	weapon = WeaponDie.new(Rules.d8)
	weapon.roll_damage(8, false)
	assert_bool(weapon.is_alive()).is_true()
