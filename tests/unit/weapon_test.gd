extends GdUnitTestSuite

## Weapons as carried: marking faces, ruin, and picking the first usable one.

const KNIFE: String = "uid://dekvqsgavj6iv"  # knife.tres
const SWORD: String = "uid://bect44b53knlo"  # sword.tres
const CLUB: String = "uid://be50bgdx1p7g0"  # club.tres
const BATTERED: String = "uid://cjt8mg5iiet5k"  # battered.tres

func test_create_profile() -> void:
	var crossbow: WeaponProfile = WeaponProfile.create("Crossbow", Rules.d6, Rules.INTELLIGENCE)
	assert_str(crossbow.name).is_equal("Crossbow")
	assert_object(crossbow.die).is_same(Rules.d6)
	assert_object(crossbow.wield_attribute).is_same(Rules.INTELLIGENCE)
	assert_object(WeaponProfile.create("Club", Rules.d6).wield_attribute).is_same(Rules.STRENGTH)

func test_create_ruined() -> void:
	var knife: Weapon = Weapon.create(load(KNIFE), [] as Array[int], true)
	assert_bool(knife.is_usable()).is_false()

func test_knife() -> void:
	var knife: WeaponProfile = load(KNIFE)
	assert_str(knife.name).is_equal("Knife")
	assert_object(knife.die).is_same(Rules.d6)
	assert_object(knife.wield_attribute).is_same(Rules.STRENGTH)

func test_sword_and_club() -> void:
	var sword: WeaponProfile = load(SWORD)
	assert_str(sword.name).is_equal("Sword")
	assert_object(sword.die).is_same(Rules.d8)
	var club: WeaponProfile = load(CLUB)
	assert_str(club.name).is_equal("Club")
	assert_object(club.die).is_same(Rules.d6)

func test_marking_a_new_face() -> void:
	var knife: Weapon = Weapon.create(load(KNIFE))
	assert_int(knife.mark(5)).is_equal(5)
	assert_int(knife.mark(2)).is_equal(2)
	assert_array(knife.marked_faces).is_equal([2, 5])
	assert_bool(knife.is_usable()).is_true()

func test_marking_a_marked_face_marks_the_next_higher_one() -> void:
	var knife: Weapon = Weapon.create(load(KNIFE))
	knife.mark(5)
	assert_int(knife.mark(5)).is_equal(6)
	assert_bool(knife.is_usable()).is_true()

func test_no_higher_face_left_ruins() -> void:
	var knife: Weapon = Weapon.create(load(KNIFE))
	knife.mark(5)
	knife.mark(6)
	assert_int(knife.mark(5)).is_equal(0)
	assert_bool(knife.is_usable()).is_false()
	# Still carried and visible, just unusable
	assert_array(knife.marked_faces).is_equal([5, 6])

func test_first_usable_skips_ruined() -> void:
	var weapons: Array[Weapon] = Weapon.carry([load(KNIFE), load(KNIFE)] as Array[WeaponProfile])
	assert_object(Weapon.get_first_usable(weapons)).is_same(weapons[0])
	weapons[0].ruined = true
	assert_object(Weapon.get_first_usable(weapons)).is_same(weapons[1])
	weapons[1].ruined = true
	assert_object(Weapon.get_first_usable(weapons)).is_null()

func test_carrying_gives_each_its_own_state() -> void:
	var weapons: Array[Weapon] = Weapon.carry([load(KNIFE), load(KNIFE)] as Array[WeaponProfile])
	weapons[0].mark(3)
	assert_bool(weapons[1].is_marked(3)).is_false()

func test_weapon_keeps_its_state_as_a_resource() -> void:
	# Authored in a given state: already marked (low faces, so rebalancing the knife to d6 or more does not matter)
	var knife: Weapon = Weapon.create(load(KNIFE), [5, 2] as Array[int])
	assert_array(knife.marked_faces).is_equal([2, 5])
	var path: String = "user://weapon_test_knife.tres"
	assert_int(ResourceSaver.save(knife, path)).is_equal(OK)
	var loaded: Weapon = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_object(loaded.weapon_profile).is_same(load(KNIFE))
	assert_array(loaded.marked_faces).is_equal([2, 5])
	assert_bool(loaded.ruined).is_false()
	assert_int(loaded.mark(5)).is_equal(6)

func test_marking_all_faces() -> void:
	var knife: Weapon = Weapon.create(load(KNIFE))
	knife.mark_all()
	assert_array(knife.marked_faces).is_equal([1, 2, 3, 4, 5, 6])
	assert_bool(knife.is_usable()).is_true()
	assert_int(knife.mark(3)).is_equal(0)

func test_battered_marks_two_different_faces() -> void:
	var battered: MarkRandomFacesModifier = load(BATTERED)
	assert_int(battered.count).is_equal(2)
	for _repeat: int in 50:
		var club: Weapon = Weapon.carry([load(CLUB)] as Array[WeaponProfile], [battered] as Array[EquipmentModifier])[0]
		assert_int(club.marked_faces.size()).is_equal(2)
		assert_int(club.marked_faces[0]).is_not_equal(club.marked_faces[1])
		for face: int in club.marked_faces: assert_int(face).is_between(1, 6)
		assert_bool(club.is_usable()).is_true()

func test_marking_more_faces_than_the_die_has_never_ruins() -> void:
	var modifier: MarkRandomFacesModifier = MarkRandomFacesModifier.new()
	modifier.count = 12
	var club: Weapon = Weapon.carry([load(CLUB)] as Array[WeaponProfile], [modifier] as Array[EquipmentModifier])[0]
	assert_array(club.marked_faces).is_equal([1, 2, 3, 4, 5, 6])
	assert_bool(club.is_usable()).is_true()

func test_modifiers_apply_to_every_weapon_and_stack() -> void:
	var battered: MarkRandomFacesModifier = load(BATTERED)
	var weapons: Array[Weapon] = Weapon.carry([load(CLUB), load(KNIFE)] as Array[WeaponProfile], [battered, battered] as Array[EquipmentModifier])
	for weapon: Weapon in weapons: assert_int(weapon.marked_faces.size()).is_equal(4)

func test_weapon_profiles_stay_untouched() -> void:
	var club: Weapon = Weapon.carry([load(CLUB)] as Array[WeaponProfile], [load(BATTERED)] as Array[EquipmentModifier])[0]
	club.mark_all()
	assert_int(club.marked_faces.size()).is_equal(6)
	assert_array(Weapon.carry([load(CLUB)] as Array[WeaponProfile])[0].marked_faces).is_empty()
