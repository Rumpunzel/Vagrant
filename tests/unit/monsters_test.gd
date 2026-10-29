extends GdUnitTestSuite

## Monsters: spawning and identity by spawning page, host (generic events), profile and index; runtime state.

var _monsters: Monsters
var _page: AdventurePage
var _other_page: AdventurePage
var _cutthroat: MonsterProfile
var _brute: MonsterProfile

func before_test() -> void:
	_monsters = auto_free(Monsters.new())
	add_child(_monsters)
	_page = AdventurePage.new()
	_other_page = AdventurePage.new()
	_cutthroat = TestMonsters.cutthroat()
	_brute = TestMonsters.brute()

func test_same_key_returns_same_monster() -> void:
	var cutthroat: Monster = _monsters.get_monster(_page, _cutthroat)
	assert_object(_monsters.get_monster(_page, _cutthroat)).is_same(cutthroat)
	assert_object(cutthroat.spawned_from).is_same(_page)
	assert_object(cutthroat.get_parent()).is_same(_monsters)

func test_index_page_and_profile_tell_monsters_apart() -> void:
	var cutthroat: Monster = _monsters.get_monster(_page, _cutthroat)
	var second_cutthroat: Monster = _monsters.get_monster(_page, _cutthroat, 1)
	var brute: Monster = _monsters.get_monster(_page, _brute)
	var other_cutthroat: Monster = _monsters.get_monster(_other_page, _cutthroat)
	# Identity, not equality: two fresh cutthroats have equal properties
	for other: Monster in [second_cutthroat, brute, other_cutthroat]: assert_object(other).is_not_same(cutthroat)
	assert_int(_monsters.get_child_count()).is_equal(4)
	assert_int(_monsters.get_all_monsters_of_type(_cutthroat).size()).is_equal(3)
	assert_array(_monsters.get_all_monsters_of_type(MonsterProfile.new())).is_empty()

func test_hosts_tell_monsters_apart() -> void:
	var shared: Monster = _monsters.get_monster(_page, _cutthroat)
	var at_host: Monster = _monsters.get_monster(_page, _cutthroat, 0, _other_page)
	assert_object(at_host).is_not_same(shared)
	assert_object(_monsters.get_monster(_page, _cutthroat, 0, _other_page)).is_same(at_host)
	assert_object(at_host.spawned_from).is_same(_page)

func test_injuries_persist_but_breath_recovers() -> void:
	var cutthroat: Monster = _monsters.get_monster(_page, _cutthroat)
	cutthroat.suffer_injury(Injury.new(2))
	cutthroat.lose_breath_dice(cutthroat.get_breath_dice_pool())
	assert_bool(cutthroat.is_out_of_breath()).is_true()
	assert_int(cutthroat.get_injury_total()).is_equal(2)
	cutthroat.recover_breath()
	var again: Monster = _monsters.get_monster(_page, _cutthroat)
	assert_bool(again.is_out_of_breath()).is_false()
	assert_int(again.get_breath_dice_count()).is_equal(3)
	assert_int(again.get_score(Rules.STRENGTH)).is_equal(3)

func test_weapons_come_from_profile() -> void:
	var cutthroat: Monster = _monsters.get_monster(_page, _cutthroat)
	assert_int(cutthroat.weapons.size()).is_equal(1)
	assert_bool(cutthroat.has_natural_weapons()).is_false()
	assert_object(cutthroat.get_weapon()).is_same(cutthroat.weapons[0])
	# Marks stay with this monster
	cutthroat.weapons[0].mark(3)
	assert_bool(_monsters.get_monster(_page, _cutthroat).weapons[0].is_marked(3)).is_true()
	assert_bool(_monsters.get_monster(_page, _cutthroat, 1).weapons[0].is_marked(3)).is_false()

func test_equipment_modifiers_apply_to_all_equipment_of_each_monster() -> void:
	var battered: MarkRandomFacesModifier = MarkRandomFacesModifier.new()
	battered.count = 2
	_cutthroat.armor = [ArmorProfile.create("Helmet", [5, 10] as Array[int])] as Array[ArmorProfile]
	_cutthroat.shields = [ShieldProfile.create("Buckler", Rules.d6)] as Array[ShieldProfile]
	_cutthroat.equipment_modifiers = [battered] as Array[EquipmentModifier]
	var cutthroat: Monster = _monsters.get_monster(_page, _cutthroat)
	for equipment: Equipment in [cutthroat.get_weapon(), cutthroat.armor[0], cutthroat.shields[0]]: assert_int(equipment.marked_faces.size()).is_equal(2)
	# Every cutthroat gets its own knife and marks
	var other_knife: Weapon = _monsters.get_monster(_page, _cutthroat, 1).get_weapon()
	assert_object(other_knife).is_not_same(cutthroat.get_weapon())
	assert_int(other_knife.marked_faces.size()).is_equal(2)

func test_monster_without_weapons_has_natural_weapons() -> void:
	var brute: Monster = _monsters.get_monster(_page, _brute)
	assert_bool(brute.has_natural_weapons()).is_true()
	assert_object(brute.get_weapon()).is_null()

func test_attack_comes_from_profile() -> void:
	assert_object(_monsters.get_monster(_page, _cutthroat).get_attack().get_stance()).is_same(Rules.STRENGTH)
	var unnerver: Monster = _monsters.get_monster(_page, TestMonsters.unnerver(Rules.AGILITY))
	assert_object(unnerver.get_attack().get_stance()).is_same(Rules.INTELLIGENCE)
	assert_object(unnerver.get_attack().get_nerves_target()).is_same(Rules.AGILITY)
	# Without an authored attack, monsters threaten with Guts
	assert_object(MonsterProfile.new().attack.get_stance()).is_same(Rules.STRENGTH)
	assert_object(MonsterProfile.new().attack.get_nerves_target()).is_null()

func test_unarmed_monster_threatens_with_guts() -> void:
	var unnerver: Monster = _monsters.get_monster(_page, TestMonsters.unnerver())
	unnerver.weapons[0].ruined = true
	assert_object(unnerver.get_attack()).is_same(Monster.UNARMED_ATTACK)
	assert_object(unnerver.get_attack().get_stance()).is_same(Rules.STRENGTH)
	# Natural weapons can't be lost
	var brute_profile: MonsterProfile = TestMonsters.brute()
	brute_profile.attack = NervesAttack.new()
	assert_object(_monsters.get_monster(_page, brute_profile).get_attack()).is_same(brute_profile.attack)
