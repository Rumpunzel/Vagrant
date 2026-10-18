extends GdUnitTestSuite

## Character creation hands out its starting gear once and shows it in the inventory.

const CHARACTER_CREATION: String = "uid://cc3qx1qt3ie00"  # character_creation.tscn
const DORIAN: String = "uid://73nsysikxf7j"  # dorian.tres
const SWORD: String = "uid://bect44b53knlo"  # sword.tres
const GAMBESON: String = "uid://cgbwu4wq14rtm"  # gambeson.tres
const HELMET: String = "uid://d0vokcalj7e4j"  # helmet.tres
const BUCKLER: String = "uid://drsjitqot54x4"  # buckler.tres
const RATIONS: String = "uid://b2g8kvymsuwvd"  # rations.tres
const WATERSKIN: String = "uid://mawuoxnjayca"  # waterskin.tres

var _creation: CharacterCreation
var _profile: CharacterProfile

func before_test() -> void:
	_creation = auto_free(load(CHARACTER_CREATION).instantiate())
	_profile = (load(DORIAN) as CharacterProfile).duplicate(true)
	_profile.weapons = [] as Array[WeaponProfile]
	_profile.armor = [] as Array[ArmorProfile]
	_profile.shields = [] as Array[ShieldProfile]
	_profile.items = {} as Dictionary[ItemProfile, int]
	_creation.character_profile = _profile
	add_child(_creation)

func after_test() -> void:
	await await_millis(200)

func test_created_character_gets_starting_gear() -> void:
	var created: Array[CharacterProfile] = []
	_creation.character_created.connect(func(character_profile: CharacterProfile) -> void: created.append(character_profile))
	_creation._on_character_confirmed("Tester")
	assert_int(created.size()).is_equal(1)
	_assert_starting_gear()

func test_gear_is_handed_out_once_and_shown() -> void:
	# A valid profile goes straight to the origins stage, where the inventory appears
	assert_bool(_creation._inventory.visible).is_true()
	assert_array(_creation._inventory.get_entries()).contains(["Sword (d10)", "Buckler (d6)", "Rations ×3", "Waterskin"])
	_creation._on_character_confirmed("Tester")
	_assert_starting_gear()

func _assert_starting_gear() -> void:
	assert_array(_profile.weapons).is_equal([load(SWORD)])
	assert_array(_profile.armor).is_equal([load(GAMBESON), load(HELMET)])
	assert_array(_profile.shields).is_equal([load(BUCKLER)])
	assert_int(_profile.items[load(RATIONS) as ItemProfile]).is_equal(3)
	assert_int(_profile.items[load(WATERSKIN) as ItemProfile]).is_equal(1)
