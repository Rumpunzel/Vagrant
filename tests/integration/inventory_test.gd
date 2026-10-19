extends GdUnitTestSuite

## The inventory panel lists a profile's gear, and a character's gear with marks as they happen.

const INVENTORY: String = "uid://im1nhm5y1kim"  # inventory.tscn
const CHARACTER: String = "uid://bl0pdxri24fnh"  # character.tscn

var _inventory: Inventory
var _profile: CharacterProfile

func before_test() -> void:
	_inventory = auto_free(load(INVENTORY).instantiate())
	add_child(_inventory)
	_profile = TestCharacters.adventurer()
	_profile.weapons = [WeaponProfile.create("Sword", Rules.d10)] as Array[WeaponProfile]
	_profile.armor = [ArmorProfile.create("Gambeson", [] as Array[int], 1), ArmorProfile.create("Helmet", [5, 10] as Array[int])] as Array[ArmorProfile]
	_profile.shields = [ShieldProfile.create("Buckler", Rules.d6)] as Array[ShieldProfile]
	_profile.items = {ItemProfile.create("Rations"): 3, ItemProfile.create("Waterskin"): 1} as Dictionary[ItemProfile, int]

func test_lists_a_profile() -> void:
	_inventory.setup(_profile)
	assert_array(_inventory.get_entries()).is_equal(["Sword (d10)", "Gambeson (−1 damage)", "Helmet (blocks 5, 10)", "Buckler (d6)", "Rations ×3", "Waterskin"])

func test_shows_marks_as_they_happen() -> void:
	var character: Character = auto_free(load(CHARACTER).instantiate())
	add_child(character)
	character.character_profile = _profile
	_inventory.show_character(character)
	character.weapons[0].mark(7)
	assert_array(_inventory.get_entries()).contains(["Sword (d10) — marked 7"])
	character.armor[1].mark(10)
	character.armor[1].mark(10)
	assert_array(_inventory.get_entries()).contains(["Helmet (blocks 5, 10) — ruined"])

func test_items_are_the_characters_own() -> void:
	var character: Character = auto_free(load(CHARACTER).instantiate())
	add_child(character)
	character.character_profile = _profile
	var rations: ItemProfile = _profile.items.keys()[0]
	character.items[rations] = 2
	assert_int(_profile.items[rations]).is_equal(3)
