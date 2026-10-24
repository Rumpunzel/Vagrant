class_name TestCharacters
extends RefCounted

## Characters owned by the tests, so rebalancing the game's characters and origins does not break them.

## Guts, Blood and Nerves 7 (rolled 3 + 4, no doubles), two origins without abilities or modifiers, no gear
static func adventurer() -> CharacterProfile:
	var portrait: PlaceholderTexture2D = PlaceholderTexture2D.new()
	portrait.size = Vector2(64, 64)
	var scores: Dictionary[CharacterAttribute, RolledAttributeScore] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = TestCharacters.rolled(3, 4)
	var origins: Array[Origin] = [TestCharacters.origin("Wanderer"), TestCharacters.origin("Drifter")]
	return CharacterProfile.create("Tester", portrait, scores, origins, "Test Adventurer")

static func origin(origin_name: String) -> Origin:
	var new_origin: Origin = Origin.new()
	new_origin.name = origin_name
	var icon: PlaceholderTexture2D = PlaceholderTexture2D.new()
	icon.size = Vector2(16, 16)
	new_origin.icon = icon
	return new_origin

static func rolled(first: int, second: int) -> RolledAttributeScore:
	return RolledAttributeScore.new([Die.new(Rules.d6, first), Die.new(Rules.d6, second)] as Array[Die])
