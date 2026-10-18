extends GdUnitTestSuite

## Character creation hands out its starting weapons and armour.

const CHARACTER_CREATION: String = "uid://cc3qx1qt3ie00"  # character_creation.tscn
const DORIAN: String = "uid://73nsysikxf7j"  # dorian.tres
const SWORD: String = "uid://bect44b53knlo"  # sword.tres
const GAMBESON: String = "uid://cgbwu4wq14rtm"  # gambeson.tres
const HELMET: String = "uid://d0vokcalj7e4j"  # helmet.tres

func after_test() -> void:
	await await_millis(200)

func test_created_character_gets_starting_gear() -> void:
	var creation: CharacterCreation = auto_free(load(CHARACTER_CREATION).instantiate())
	add_child(creation)
	var profile: CharacterProfile = (load(DORIAN) as CharacterProfile).duplicate(true)
	profile.weapons = [] as Array[WeaponProfile]
	profile.armor = [] as Array[ArmorProfile]
	creation.character_profile = profile
	var created: Array[CharacterProfile] = []
	creation.character_created.connect(func(character_profile: CharacterProfile) -> void: created.append(character_profile))
	creation._on_character_confirmed("Tester")
	assert_int(created.size()).is_equal(1)
	assert_int(profile.weapons.size()).is_equal(1)
	assert_object(profile.weapons[0]).is_same(load(SWORD))
	assert_array(profile.armor).is_equal([load(GAMBESON), load(HELMET)])
